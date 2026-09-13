#!/bin/bash

###############################################################################
# Meta社 llama.cpp と Alibaba Cloud社 Qwen3.0 でオンプレ/ローカルLLMの実験
# ex03_llm_serv_basic_v3.sh [Quen 3.0対応]
#
#                                              Copyright (c) 2026 Wataru KUNINO
###############################################################################

# LLM 設定 ####################################################################
llama_home="$HOME/llama.cpp/"                       # llama.cpp のパス
llama_srv="${llama_home}build/bin/llama-server"     # llamaサーバー実行アプリ
model_name="Qwen3-4B-Q4_K_M.gguf"                   # モデル名(要ダウンロード)
model_path="${llama_home}models/${model_name}"      # モデルのパス
llama_opts=""                                       # llama用オプション用の変数
server_port=8080                                    # llamaサーバー通信ポート

# LLM 入力用プロンプト ########################################################
prompt='あなたはつぶやきを生成するアシスタントです。
    一般的な生活で発生する無数の出来事から具体的なものを1つを選んで、つぶやいてください。
    出力条件:
    - 20～40文字程度
    - 文体は柔らかくフレンドリーに
    - 政治,宗教,差別表現は含めない
    - JSON形式{"response":"..."}のみを応答
    /no_think'
echo "prompt: $prompt"

# LLM サーバー用オプション設定 ################################################
llama_opts+="--log-disable "        # ログ出力の無効化
llama_opts+="--temp 0.5 "           # 小さいほど生成の揺らぎを抑制 0.2～0.5
llama_opts+="--top-k 50 "           # 採用候補語数。多いほど高品質だが低速度に
llama_opts+="--top-p 0.9 "          # 候補語の採用時の確率閾値。破綻抑制。
llama_opts+="--repeat-penalty 1.1 " # 同じ語句の反復抑制(推奨値1.05～1.2)
llama_opts+="-n 128 "               # 最大生成トークン数(暴走や過生成を防止)
llama_opts+="-t 4 "                 # 生成時に使用するCPUスレッド数
# llama_opts+="--fit on "           # メモリーの利用可能容量に合わせた自動調整
# llama_opts+="--fit-target 1024 "  # メモリーの自動調整の目標値(1024MB)
llama_opts+="--ctx-size 2048 "      # 総文脈トークン長を制限(0=モデル推奨値)
# llama_opts+="--no-mmap "          # MMAP無効。モデル読込時間が増えるが安定
# llama_opts+="--no-repack "        # 過去トークン用キャッシュの再構築を無効化
# llama_opts+="--reasoning off "    # 推論OFF

# llama.cpp と Qwen2.5 の存在を確認する #######################################
if [ ! -x "${llama_srv}" ]; then
    echo "エラー: llama_srv が見つかりません: ${llama_srv}"
    exit 1
fi
if [ ! -f "${model_path}" ]; then
    echo "エラー: モデルファイルが見つかりません: ${model_path}"
    exit 1
fi

# LLM サーバー起動 ############################################################
if ! curl -s --fail "http://localhost:${server_port}/" > /dev/null ; then
    echo "llama-server を起動します。10秒待機中..."
    # echo "${llama_srv}" -m "${model_path}" ${llama_opts} --port ${server_port}
    "${llama_srv}" \
        -m "${model_path}" \
        ${llama_opts} \
        --port ${server_port} \
        > /dev/null 2>&1 &
    sleep 10
fi

while true; do
    # LLM 実行 ################################################################
    echo "つぶやき生成中..."
    sleep 3
    request=$(jq -n \
      --arg model "$model_name" \
      --arg content "$prompt" \
      '{model: $model, messages:[{role: "user", content: $content}]}')
    raw=$(curl -s \
      -H "Content-Type: application/json" \
      -d "$request" \
      "http://localhost:${server_port}/v1/chat/completions")

    if [ -z "$raw" ]; then
        echo "ERROR: API 応答が空です"
        continue
    fi
    # JSON部を抽出 ############################################################
    content=`echo "$raw" | jq -r '.choices[0].message.content // .choices[0].message.reasoning_content' 2>/dev/null`
    if [ -z "$content" ] || [ "$content" = "null" ]; then
        echo "ERROR: API 応答から content が取得できません"
        echo "raw:" "$raw"
        continue
    fi
    json_text=`echo "$content"| sed -n '/^[ :]*\([A-Za-z:]\+\)\? *{/,/^[ ]*}/p'`
    if [ -z "$json_text" ]; then
        response=$content
    else
        # JSONから応答を抽出 ##################################################
        response=`echo "$json_text"| jq -r '.response' 2>/dev/null`
        if [ -z "$response" ] || [ "$response" = "null" ]; then
            echo "ERROR: JSON の response フィールドが取得できません"
            echo "json:" "${json_text}"
            continue
        fi
    fi
    # LLM 応答を表示する ######################################################
    echo "LLM 応答 >" "${response}"
    echo "--------------------------------------------------------------------"
done

###############################################################################
# 実行結果の例 ご注意:1回目の実行には1～2分を要します(モデルの読み込みのため)
###############################################################################
# pi@raspberrypi:~/bash/practical/llama_cpp ./ex03_llm_serv_basic_v3.sh
# prompt: あなたはつぶやきを生成するアシスタントです。
#     日常生活で発生する無数の出来事から1つを選んで、それを基につぶやいてください。
#     出力条件:
#     - 20～40文字程度
#     - 文体は柔らかくフレンドリーに
#     - 政治,宗教,差別表現は含めない
#     - JSON形式{"response":"..."}のみを応答
# llama-server を起動します。10秒待機中...
# つぶやき生成中...
# --------------------------------------------------------------------
# LLM 応答 > 朝の散歩で出会った猫が私の影をながめていた。
# --------------------------------------------------------------------
# LLM 応答 > 朝から雨が降ってたけど、今日も元気でいたよ。
# --------------------------------------------------------------------
# LLM 応答 > 昨日の雨の中で、突然花が咲いた。心がほっこりした。
# --------------------------------------------------------------------
# LLM 応答 > 朝のコーヒーの香りが部屋を満たし、今日も一日が始まったね。
# --------------------------------------------------------------------
# LLM 応答 > 朝の散歩で出会った猫が、私の影を見つめていたね。
# --------------------------------------------------------------------
# LLM 応答 > 今日も一日が過ぎるのを見守っている気がしてきました。
# --------------------------------------------------------------------
# LLM 応答 > 今日は朝から雨が降って、心配してたけどやっと晴れたよ。
# --------------------------------------------------------------------
# LLM 応答 > 朝のコーヒーを淹れたとき、突然の雨が降って慌てた。
# --------------------------------------------------------------------
# LLM 応答 > 今日も一杯のコーヒーを飲みながら、小さな幸せを味わう日だったね。
###############################################################################
