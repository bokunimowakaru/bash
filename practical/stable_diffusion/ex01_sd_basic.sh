#!/bin/bash

###############################################################################
# Automatic1111 Stable Diffusion WebUI のAPIを使って画像生成指示を行います。
#
#                                              Copyright (c) 2025 Wataru KUNINO
###############################################################################
# 注意点
# ・Stable Diffusion をCPUで実行するので、生成には5～6分の時間を要します。
# ・JSONデータからBase64を抽出するのにjqコマンドを使用します。
#   $ sudo apt install jq ⏎
# ・Stable Diffusion WebUI 起動時に、引数「--api」を渡す必要があります。
#   webui-user.sh 内に下記を追記してください。
#   export COMMANDLINE_ARGS="${COMMANDLINE_ARGS} --api"
###############################################################################

sampler="DPM++ 2M"          # サンプラー方式（画像生成のアルゴリズム）
width=512                   # 画像解像度（幅）
height=256                  # 画像解像度（高さ）
steps=10                    # 生成ステップ数（多いほど高品質）
cfg_scale=7                 # プロンプトの忠実度（高いほどプロンプトに忠実）
seed=-1                     # 乱数シード（数値:再現性確保,-1:ランダム）
api_url="127.0.0.1:7860"    # アクセス先URL
output_file="ex01_sd_basic.png" # 出力ファイル名

# 画像生成用プロンプト
prompt="A professional landscape photograph of European scenery."

echo "Stable Diffusion API, 画像生成中..."
curl -o response.json \
    -X POST "http://"${api_url}"/sdapi/v1/txt2img" \
    -H "Content-Type: application/json" \
    -d "{
        \"prompt\": \"$prompt\",
        \"sampler_name\": \"$sampler\",
        \"width\": $width,
        \"height\": $height,
        \"steps\": $steps,
        \"cfg_scale\": $cfg_scale,
        \"seed\": $seed
    }"

# Base64 画像データを抽出してデコード (要jqコマンド)し、ファイル保存
image_base64=$(jq -r '.images[0]' response.json)
if [ -z "$image_base64" ] || [ "$image_base64" = "null" ]; then
    echo "[ERROR] 画像データが取得できませんでした"
    exit 1
fi
echo "$image_base64" | base64 --decode > "$output_file"
exit 0

###############################################################################
# 参考文献 API資料
# http://localhost:7860/docs#/default/text2imgapi_sdapi_v1_txt2img_post
###############################################################################
