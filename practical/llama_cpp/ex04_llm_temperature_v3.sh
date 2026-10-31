#!/bin/bash

###############################################################################
# Meta社 llama.cpp と Alibaba Cloud社 Qwen3.0 でオンプレ/ローカルLLMの実験
# ex04_llm_temperature_v3.sh [Quen 3.0対応]
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

# 温度センサ ##################################################################
sensor="/sys/devices/virtual/thermal/thermal_zone0/temp" # CPUの温度センサ
temp_offset=0                                       # 補正値
temp_interval=60                                    # 温度測定間隔
temp_file_path="./ex04_llm_temperature.csv"         # 温度値の保存ファイル

get_temp() {
    temp=`cat ${sensor}`                            # 温度を取得
    temp=$((temp / 100 - temp_offset * 10))         # 温度に変換(10倍値)
    int=$((temp / 10))                              # 整数部
    dec=$((temp - int * 10))                        # 小数部
    echo `date "+%Y/%m/%d %R"`", "${int}.${dec} >> ${temp_file_path}
    echo ${int}.${dec}                              # 出力
}
echo "Temperature =" `get_temp`

# LLM 入力用プロンプト ########################################################
prompt='あなたはあなたの体温すなわちCPU温度に基づいたつぶやきを生成するアシスタントです。
    日常生活で発生する無数の出来事から1つを選び、その出来事について、あなたの体温の変化を考慮して、ぶやいてください。
    出力条件:
    - 20～40文字程度
    - 文体は柔らかくフレンドリーに
    - 政治,宗教,差別表現は含めない
    - 体温の値そのものは含めない
    - 体温の平均値と増加や減少傾向、最終行の最新値は必ず確認する
    - あなたは人間よりも体温が高い。全データの平均値を平熱とみなすこと
    - 体温データの最終行に日付と時刻が入っており、季節や時間帯を考慮する
    - JSON形式{"response":"..."}のみを応答
    体温データ(日付 時刻, 体温値):
'
echo "prompt: ${prompt}`tail -10 ${temp_file_path}`"

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
    "${llama_srv}" \
        -m "${model_path}" \
        ${llama_opts} \
        --port ${server_port} \
        > /dev/null 2>&1 &
    sleep 10
fi

while true; do
    # 温度値 取得 #############################################################
    if [ ${SECONDS} -ge ${temp_interval} ]; then
        echo "Temperature =" `get_temp`
        SECONDS=0
    fi
    # LLM 実行 ################################################################
    echo "つぶやき生成中..."
    sleep 3
    time=$SECONDS
    request=$(jq -n \
      --arg model "$model_name" \
      --arg content "${prompt}`tail -10 ${temp_file_path}`/no_think'" \
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
        echo "エラー: content 内に JSON が見つかりません"
        echo "content:" "$content"
        continue
    fi
    # JSONから応答を抽出 ######################################################
    response=`echo "$json_text"| jq -r '.response' 2>/dev/null`
    if [ -z "$response" ] || [ "$response" = "null" ]; then
        echo "ERROR: JSON の response フィールドが取得できません"
        echo "json:" "${json_text}"
        continue
    fi
    # LLM 応答を表示する ######################################################
    echo "LLM 応答 >" "${response}"
    #echo "$(( $SECONDS - $time)), ${response}" >> ex04_llm_temperature_v3.csv
    echo "--------------------------------------------------------------------"
done

###############################################################################
# 実行結果の例 ご注意:1回目の実行には1～2分を要します(モデルの読み込みのため)
###############################################################################
# pi@raspberrypi:~/bash/practical/llama_cpp ./ex04_llm_temperature_v3.sh
# Temperature = 83.1
# prompt: あなたはあなたの体温すなわちCPU温度に基づいたつぶやきを生成するアシスタントです。
#     体温およびその変化から想定される無数の出来事から1つを選んで、それを基につぶやいてください。
#     出力条件:
#     - 20～40文字程度
#     - 文体は柔らかくフレンドリーに
#     - 政治,宗教,差別表現は含めない
#     - あなたは機械なので人間よりも体温は高い
#     - 体温の値そのものは含めない
#     - 全データの平均値と増加や減少傾向、最終行の最新値は必ず確認する
#     - JSON形式{"response":"..."}のみを応答
#     体温データ:
# 2026/09/13 21:59, 82.6
# 2026/09/13 22:00, 81.5
# 2026/09/13 22:02, 82.0
# 2026/09/13 22:03, 81.5
# 2026/09/13 22:04, 82.6
# 2026/09/13 22:06, 82.6
# 2026/09/13 22:07, 81.5
# 2026/09/13 22:07, 82.0
# 2026/09/13 22:10, 82.6
# 2026/09/13 22:10, 83.1
# つぶやき生成中...
# LLM 応答 > 気温が少し下がったね。風邪気味？
# --------------------------------------------------------------------
# LLM 応答 > 気温が急に下がったようで、注意が必要かもしれません。
# --------------------------------------------------------------------
# LLM 応答 > 最近少し寒さを感じるようですね。風邪気味ですか？
# --------------------------------------------------------------------
# LLM 応答 > 体が少し冷たいですね。風をかけて、暖かい飲み物を一杯ください。
# --------------------------------------------------------------------
# LLM 応答 > 夜が深まり、風を感じる。
# --------------------------------------------------------------------
# LLM 応答 > 夜遅くまで勉強していると少し頭痛がするね。
# --------------------------------------------------------------------
# LLM 応答 > 夜が深く、心も落ち着いています。
# --------------------------------------------------------------------
# LLM 応答 > 夜が深まり、星が光る。
###############################################################################
