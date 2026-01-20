#!/bin/bash

###############################################################################
# Automatic1111 Stable Diffusion WebUI のAPIを使って人物画像の生成指示を行う
# [実用・汎用版][人物][メモリ計測][4GB RAM]
# 1枚の画像生成に約20分を要します。
#
# 詳細情報
# 　人物生成 = https://bokunimo.net/blog/raspberry-pi/6400/
# 　RAM 4GB  = https://bokunimo.net/blog/raspberry-pi/6228/
#
#                                         Copyright (c) 2025-2026 Wataru KUNINO
###############################################################################
# 注意点
# ・モデルに「japaneseStyleRealistic_v20」を使用します。
#   ダウンロード https://civitai.com/models/56287/japanese-style-realistic-jsr
#   保存先 stable-diffusion-webui/models/Stable-diffusion
#   ライセンス CreativeML Open RAIL-M, ※Beautiful Realistic Asians 融合モデル
# ・Stable Diffusion をCPUで実行するので、生成には約22分の時間を要します。
# ・約5.1GB～8.1GBのメモリーを使用します。8GBモデルでは節約が必要です。
#   メモリーを節約する設定方法(Swap設定を含む)は当方ブログを確認ください。
# ・解像度は低めです。 width,heightの値を増やすと高解像度になります。
# ・JSONデータからBase64を抽出するのにjqコマンドを使用します。
#   $ sudo apt install jq ⏎
# ・Stable Diffusion WebUI 起動時に、引数「--api」を渡す必要があります。
#   webui-user.sh 内に下記を追記してください。
#   export COMMANDLINE_ARGS="${COMMANDLINE_ARGS} --api"
###############################################################################

model="japaneseStyleRealistic_v20" # モデル名
# ↑ 標準モデルを使用する場合は model="v1-5-pruned-emaonly" に変更してください
sampler="DPM++ 2M"          # サンプラー方式（画像生成のアルゴリズム）
scheduler="Karras"          # スケジューラー方式（ノイズ除去アルゴリズム）
width=256                   # 画像解像度（幅）
height=344                  # 画像解像度（高さ）
steps=20                    # 生成ステップ数（多いほど高品質）
cfg_scale=7                 # プロンプトの忠実度（高いほどプロンプトに忠実）
seed=-1                     # 乱数シード（数値:再現性確保,-1:ランダム）
restore_faces="false"       # 遠景で人物が小さい場合の顔補正(GFPGAN/CodeFormer)
tiling="false"              # 壁紙などのパターン状のタイル画像の補正
clip_skip=1                 # CLIP スキップ（1～2）実写風の画像では1
eta=0                       # サンプラーのノイズ量（0～1）
s_churn=0                   # サンプラーの揺らぎ
s_noise=1                   # サンプラーのノイズ量
api_url="127.0.0.1:7860"    # アクセス先URL
app_name=`basename "$0"`    # 実行ファイル名を取得
output_file_pfx=${app_name:0:7} # 出力ファイル用の接頭語を作成
repeat=-1                   # 生成回数(-1で永続)
interval_min=29             # 連続生成間隔(分), 0=間隔を開けずに連続生成
nationality="Japanese"      # 国籍

# 画像生成用プロンプト
humans=(
    "a ${nationality} masculine man with short hair, no makeup"
    "a ${nationality} woman"
    "a ${nationality} 20-year-old handsome guy with short hair, no makeup"
    "a ${nationality} 20-year-old girl"
)
clothes=("buisiness suit" "casual suit" "concierge uniform")
scenes=("in a modern apartment" "on a sidewalk" "in a office")
humans_num=${#humans[*]}
clothes_num=${#clothes[*]}
scenes_num=${#scenes[*]}

get_prompt(){
    echo -n "An upper-body portrait photograph of "
    echo -n "(${humans[$(( $RANDOM % humans_num ))]}, "
    echo -n "wears ${clothes[$(( $RANDOM % clothes_num ))]}), "
    echo -n "natural expression of a smile, realistic eyes, facing camera, "
    echo -n "clear facial features, centered composition, "
    echo -n "${scenes[$(( $RANDOM % scenes_num ))]}, "
    echo -n "professional DSLR photography. "
}
negative_prompt="low quality, blurry, "
# negative_prompt+="cropped face, close-up, extreme zoom, "
# negative_prompt+="deformed face, unrealistic eyes, 
# negative_prompt+="bad anatomy, extra arms, bad fingers, "
# negative_prompt+="cartoon, painting, sketch, "
negative_prompt+="nsfw, voluptuous, "
negative_prompt+="kimono, japanese clothes, monochrome. "

# モデルの設定
echo "モデル設定中 =" $model
res=$(curl -s -w "%{http_code}" -o res.json \
     -X POST "http://${api_url}/sdapi/v1/options" \
     -H "Content-Type: application/json" \
     -d "{\"sd_model_checkpoint\": \"$model\"}"
)
if [ "${res:(-3)}" != "200" ]; then
    echo "[ERROR] API - OPTIONS モデル設定時にエラーが発生しました (HTTP $http_code)"
    exit 1
fi

( # メモリ使用量モニター・サブプロセス
    rm -f memlog.csv
    while true; do
    echo -n `date -Iseconds`", " >> memlog.csv
    ps -o vsz,rss,pss,uss,command -C python --sort=-rss |grep launch.py |head -1 \
        |awk '{print $1",",$2",",$3",",$4}' >> memlog.csv
    sleep 2
    done
) &
child_pid=$!
trap 'kill $child_pid' EXIT

# 永久ループ
while true; do
    prompt=`get_prompt`
    echo -e "Prompt: \n"${prompt}
    echo "Stable Diffusion API: 画像生成中..." `date +"%H:%M:%S"`; SECONDS=0
    output_file=${output_file_pfx}"_"`date +"%2d_%H%M"`".png"
    res=$(curl -s -w "%{http_code}" -o res.json \
      -X POST "http://${api_url}/sdapi/v1/txt2img" \
      -H "Content-Type: application/json" \
      -d "{
            \"prompt\": \"$prompt\",
            \"negative_prompt\": \"$negative_prompt\",
            \"sampler_name\": \"$sampler\",
            \"scheduler\": \"$scheduler\",
            \"width\": $width,
            \"height\": $height,
            \"steps\": $steps,
            \"cfg_scale\": \"$cfg_scale\",
            \"seed\": $seed,
            \"restore_faces\": \"$restore_faces\",
            \"tiling\": \"$tiling\",
            \"clip_skip\": \"$clip_skip\",
            \"eta\": \"$eta\",
            \"s_churn\": \"$s_churn\",
            \"s_noise\": \"$s_noise\"
          }"
    )
    echo "終了しました 所要時間 $SECONDS 秒 (約 $(((SECONDS + 30) / 60)) 分)"
    echo -n "メモリ使用量: 最大 = "
    awk -F, '{if($3>max){max=$3}}END{print int(max/1024+0.5) " MB"}' memlog.csv
    echo -n "　　　　　　: 平均 = "
    awk -F, '{sum+=$3; count++} END{print int(sum/count/1024+0.5)" MB"}' memlog.csv
    echo -n "　　　　　　: ３σ =  "
    awk -F, '{sum+=$3; sumsq+=$3*$3; count++} END{\
        mean=sum/count; print int(3*sqrt(sumsq/count - mean*mean)/1024+0.5)" MB"\
    }' memlog.csv
    echo -n "メモリ確保量: 最大 = "
    awk -F, '{if($2>max){max=$2}}END{print int(max/1024+0.5) " MB"}' memlog.csv
    echo -n "　　　　　　: 平均 = "
    awk -F, '{sum+=$2; count++} END{print int(sum/count/1024+0.5)" MB"}' memlog.csv
    echo -n "　　　　　　: ３σ =  "
    awk -F, '{sum+=$2; sumsq+=$2*$2; count++} END{\
        mean=sum/count; print int(3*sqrt(sumsq/count - mean*mean)/1024+0.5)" MB"\
    }' memlog.csv

    # HTTPリゾルトコードの確認
    http_code="${res:(-3)}"
    if [ "${http_code}" != "200" ]; then
        echo "[ERROR] API エラーが発生しました (HTTP $http_code)"
        if [ "${http_code}" = "000" ]; then
            echo "Stable Diffusion からの応答がありません"
            sleep 30
            continue
        fi
        echo "レスポンス内容:"
        cat res.json
        sleep 30
        continue
    fi
    # Base64 画像データを抽出してデコード (要jqコマンド)し、ファイル保存
    image_base64=$(jq -r '.images[0]' res.json)
    if [ -z "$image_base64" ] || [ "$image_base64" = "null" ]; then
        echo "[ERROR] 画像データが取得できませんでした"
        sleep 30
        continue
    fi
    echo "$image_base64" | base64 --decode > "$output_file"
    echo "生成した画像を保存しました $output_file"
    # ExifToolがインストールされていた場合に生成時間をEXIFに追記する
    which exiftool
    if [ $? -eq 0 ]; then
        exiftool -ExposureTime=${SECONDS} -overwrite_original "$output_file"
    fi
    repeat=$((repeat-1))
    if [ $repeat -le -1 ]; then
        repeat=-1           # 負の値の時に永久ループ
    fi
    if [ $repeat -eq 0 ]; then
        echo "終了します"
        exit 0
    fi
    time_d=$(( interval_min * 60 - SECONDS ))
    if [ $time_d -gt 0 ]; then
        echo "次回の実行を待機中("${time_d}"秒)..."
        sleep $((time_d))
    fi
done

###############################################################################
# 参考文献 API資料
# http://localhost:7860/docs#/default/text2imgapi_sdapi_v1_txt2img_post
###############################################################################
