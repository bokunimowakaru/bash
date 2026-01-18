#!/bin/bash

###############################################################################
# Automatic1111 Stable Diffusion WebUI のAPIを使って風景画像の生成指示を行う
# [実用・カレンダー][風景]
#
#                                              Copyright (c) 2025 Wataru KUNINO
###############################################################################
# 注意点
# ・Stable Diffusion をCPUで実行するので、生成には約10分の時間を要します。
# ・約4.9～6.3GBのメモリーを使用します。8GBモデルでは節約が必要です。
#   メモリを節約する設定方法(Swap設定を含む)は当方ブログを確認ください。
# ・解像度は低めです。 width,height,stepsの値を増やすと高解像度になります。
# ・JSONデータからBase64を抽出するのにjqコマンドを使用します。
#   $ sudo apt install jq ⏎
# ・Stable Diffusion WebUI 起動時に、引数「--api」を渡す必要があります。
#   webui-user.sh 内に下記を追記してください。
#   export COMMANDLINE_ARGS="${COMMANDLINE_ARGS} --api"
###############################################################################

sampler="DPM++ 2M"          # サンプラー方式（画像生成のアルゴリズム）
scheduler="Karras"          # スケジューラー方式（ノイズ除去アルゴリズム）
width=512                   # 画像解像度（幅）
height=256                  # 画像解像度（高さ）
steps=15                    # 生成ステップ数（多いほど高品質）
cfg_scale=8                 # プロンプトの忠実度（高いほどプロンプトに忠実）
seed=-1                     # 乱数シード（数値:再現性確保,-1:ランダム）
api_url="127.0.0.1:7860"    # アクセス先URL
app_name=`basename "$0"`    # 実行ファイル名を取得
output_file_pfx=${app_name:0:7} # 出力ファイル用の接頭語を作成
repeat=-1                   # 生成回数(-1で永続)
interval_min=10             # 連続生成間隔(分), 0=間隔を開けずに連続生成

# 情景画像生成用(プロンプトの一部)
LC_ALL=en_US.UTF8           # ロケール設定を米語に設定(英文プロンプト生成用)
sceneries=(
    "tree-lined avenue"
    "stone bridge over forest stream"
    "wooden cabin in meadow"
    "lighthouse on coastline"
    "garden path with lanterns"
    "country road with windmill"
    "vineyard on hillside"
    "old barn in field"
    "pier stretching into lake"
    "castle ruins on hill"
    "mountain hut near glacier"
    "stone wall along meadow"
    "arched bridge over river"
    "church steeple above village"
    "cobblestone path through woodland"
    "farmhouse beside stream"
    "canal with stone embankment"
    "arched gate in countryside"
    "small chapel among trees"
    "rustic fence along pasture"
)
sceneries_num=${#sceneries[*]}  # リスト数

# 永久ループ
while [ $repeat -ne 0 ]; do
    repeat=$((repeat-1))
    if [ $repeat -le -1 ]; then
        repeat=-1           # 負の値の時に永久ループ
    fi
    hour=`date +"%_H"`
    if [ $hour -le 5 ] || [ $hour -ge 19 ]; then
        hour_unit="at night, illuminated"
    elif [ $hour -eq 6 ]; then
        hour_unit="at sunrise"
    elif [ $hour -ge 7 ] && [ $hour -le 11 ]; then
        hour_unit="in the morning"
    elif [ $hour -eq 12 ]; then
        hour_unit="at noon"
    elif [ $hour -eq 18 ]; then
        hour_unit="at sunset"
    else
        hour_unit="at "${hour}" o'clock"
    fi
    month=`date +"%_m"`
    if [ $month -ge 3 ] && [ $month -le 4 ]; then
        month_unit="in spring"
    elif [ $month -ge 7 ] && [ $month -le 8 ]; then
        month_unit="in summer"
    elif [ $month -ge 9 ] && [ $month -le 10 ]; then
        month_unit="in autumn"
    elif [ $month -eq 12 ] || [ $month -eq 1 ]; then
        month_unit="in winter"
    else
        month_unit="on "`date +"%B"`
    fi
    prompt=""               # 以下、プロンプト生成部
    prompt+="A professional landscape photograph of scenery, "
    prompt+="realistic DSLR quality, suitable for a calendar. "
    prompt+="(A European "${sceneries[$(( $RANDOM % sceneries_num ))]}" "
    prompt+=${month_unit}" "${hour_unit}"), "
    prompt+="balanced cinematic composition with depth of field, natural colors, "
    prompt+="wide-angle view, high resolution, realistic photo style. "
    echo -e "Prompt: \n"${prompt}
    echo "Stable Diffusion API: 画像生成中..." `date +"%H:%M:%S"`; SECONDS=0
    output_file=${output_file_pfx}"_"`date +"%2m_%H%M"`".png"
    res=$(curl -s -w "%{http_code}" -o res.json \
      -X POST "http://${api_url}/sdapi/v1/txt2img" \
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
    )
    echo "終了しました 所要時間 $SECONDS 秒 (約 $(((SECONDS + 30) / 60)) 分)"
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
    time_d=$(( interval_min * 60 - SECONDS ))
    if [ time_d -gt 0 ]; then
        echo "次回の実行を待機中("${time_d}"秒)..."
        sleep $((time_d))
    fi
done

###############################################################################
# 参考文献 API資料
# http://localhost:7860/docs#/default/text2imgapi_sdapi_v1_txt2img_post
###############################################################################
