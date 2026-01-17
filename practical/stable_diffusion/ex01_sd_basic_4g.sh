#!/bin/bash

###############################################################################
# Automatic1111 Stable Diffusion WebUI のAPIを使って風景画像の生成指示を行う
# [実用・カレンダー][風景][メモリ計測][4GB RAM]
#
# 詳細：https://bokunimo.net/blog/raspberry-pi/6228/
#
#                                              Copyright (c) 2026 Wataru KUNINO
###############################################################################
# 注意点
# ・CPUと仮想メモリーで実行するので、生成には9～10分の時間を要します。
# ・設定方法(Swap設定を含む)は当方ブログを確認ください。
#   https://bokunimo.net/blog/raspberry-pi/6228/
# ・解像度は低めです。 width,height,stepsの値を増やすと高解像度になります。
# ・JSONデータからBase64を抽出するのにjqコマンドを使用します。
#   $ sudo apt install jq ⏎
# ・Stable Diffusion WebUI 起動時に、引数「--api」を渡す必要があります。
#   webui-user.sh 内に下記を追記してください。
#   export COMMANDLINE_ARGS="${COMMANDLINE_ARGS} --api"
###############################################################################

sampler="DPM++ 2M"          # サンプラー方式（画像生成のアルゴリズム）
scheduler="Karras"          # スケジューラー方式（ノイズ除去アルゴリズム）
width=384                   # 画像解像度（幅）
height=256                  # 画像解像度（高さ）
steps=10                    # 生成ステップ数（多いほど高品質）
cfg_scale=7                 # プロンプトの忠実度（高いほどプロンプトに忠実）
seed=-1                     # 乱数シード（数値:再現性確保,-1:ランダム）
api_url="127.0.0.1:7860"    # アクセス先URL
output_file="ex01_sd_basic.png" # 出力ファイル名

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

# 画像生成用プロンプト
prompt="A professional landscape photograph of European scenery."

echo "Stable Diffusion API: 画像生成中..." `date +"%H:%M:%S"`; SECONDS=0
curl -o response.json \
    -X POST "http://"${api_url}"/sdapi/v1/txt2img" \
    -H "Content-Type: application/json" \
    -d "{
        \"prompt\": \"$prompt\",
        \"sampler_name\": \"$sampler\",
        \"scheduler\": \"$scheduler\",
        \"width\": $width,
        \"height\": $height,
        \"steps\": $steps,
        \"cfg_scale\": $cfg_scale,
        \"seed\": $seed
    }"
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

# Base64 画像データを抽出してデコード (要jqコマンド)し、ファイル保存
image_base64=$(jq -r '.images[0]' response.json)
if [ -z "$image_base64" ] || [ "$image_base64" = "null" ]; then
    echo "[ERROR] 画像データが取得できませんでした"
    exit 1
fi
echo "$image_base64" | base64 --decode > "$output_file"
echo "生成した画像を保存しました $output_file"
exit 0

###############################################################################
# 参考文献 API資料
# http://localhost:7860/docs#/default/text2imgapi_sdapi_v1_txt2img_post
###############################################################################
