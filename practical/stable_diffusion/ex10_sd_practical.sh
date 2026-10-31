#!/bin/bash

echo "################################################################"
echo "# Automatic1111 Stable Diffusion WebUI のAPIを使った人物画像生成"
echo "# [実用・汎用版][人物][メモリ計測]"
echo "# - 1枚の画像生成に約22分を要します(Raspberry Pi 5 16GB使用時)"
echo "# - RAM 4GB モデルを使用する場合は SSD が必要です"
echo "# "
echo "# 詳細情報"
echo "# 　人物生成 = https://bokunimo.net/blog/raspberry-pi/6400/"
echo "#                          Copyright (c) 2025-2026 Wataru KUNINO"
echo "################################################################"
echo
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
sampler="DPM++ 2M"              # サンプラー方式（画像生成のアルゴリズム）
scheduler="Karras"              # スケジューラー方式（ノイズ除去アルゴリズム）
aspect="1:1"
api_url="127.0.0.1:7860"        # アクセス先URL
app_name=`basename "$0"`        # 実行ファイル名を取得
output_dir=`pwd`                # 出力先のディレクトリ
output_file_pfx=${model:0:4}    # モデル名の先頭4文字
repeat=-1                       # 生成回数(-1で永続)
interval_min=0                  # 連続生成間隔(分), 0=間隔を開けずに連続生成
clip_skip=1                     # CLIP スキップ（1～2）
if [ "${output_file_pfx}" = "japa" ]; then
    steps=20                    # 生成ステップ数（多いほど高品質）
    cfg_scale=6                 # プロンプトの忠実度（高いほどプロンプトに忠実）
    restore_faces="false"       # 遠景で人物が小さい場合の顔補正(GFPGAN/CodeFormer)
    tiling="false"              # 壁紙などのパターン状のタイル画像の補正
    eta=0                       # サンプラーのノイズ量（0～1）
    s_churn=0                   # サンプラーの揺らぎ
    s_noise=1                   # サンプラーのノイズ量
elif [ "${output_file_pfx}" = "v1-5" ]; then
    steps=27                    # 生成ステップ数（多いほど高品質）
    cfg_scale=8                 # プロンプトの忠実度（高いほどプロンプトに忠実）
    restore_faces="false"       # 遠景で人物が小さい場合の顔補正(GFPGAN/CodeFormer)
    tiling="false"              # 壁紙などのパターン状のタイル画像の補正
    eta=0                       # サンプラーのノイズ量（0～1）
    s_churn=0                   # サンプラーの揺らぎ
    s_noise=1                   # サンプラーのノイズ量
else
    steps=20                    # 生成ステップ数（多いほど高品質）
    cfg_scale=7                 # プロンプトの忠実度（高いほどプロンプトに忠実）
    restore_faces="false"       # 遠景で人物が小さい場合の顔補正(GFPGAN/CodeFormer)
    tiling="false"              # 壁紙などのパターン状のタイル画像の補正
    eta=0                       # サンプラーのノイズ量（0～1）
    s_churn=0                   # サンプラーの揺らぎ
    s_noise=1                   # サンプラーのノイズ量
fi
ram=`free -m|grep "Mem"|awk '{print $2}'`
if [ ${ram} -ge 16000 ]; then   # 16GB モデル
    if [ "${aspect}" = "1:1" ]; then
        width=512                   # 画像解像度（幅）
        height=512                  # 画像解像度（高さ）
    elif [ "${aspect}" = "1:2" ]; then 
        width=360                   # 画像解像度（幅）
        height=720                  # 画像解像度（高さ）
    elif [ "${aspect}" = "2:3" ]; then
        width=416                   # 画像解像度（幅）
        height=624                  # 画像解像度（高さ）
    else    # 9:16
        width=384                   # 画像解像度（幅）
        height=680                  # 画像解像度（高さ）
    fi
elif [ ${ram} -ge 8000 ]; then  # 8GB モデル
    if [ "${aspect}" = "1:1" ]; then 
        width=480                   # 画像解像度（幅）
        height=480                  # 画像解像度（高さ）
    elif [ "${aspect}" = "1:2" ]; then
        width=336                   # 画像解像度（幅）
        height=672                  # 画像解像度（高さ）
    elif [ "${aspect}" = "2:3" ]; then
        width=384                   # 画像解像度（幅）
        height=576                  # 画像解像度（高さ）
    else    # 9:16
        width=360                   # 画像解像度（幅）
        height=640                  # 画像解像度（高さ）
    fi
else                            # 4GB モデルを想定
    if [ "${aspect}" = "1:1" ]; then
        width=320                   # 画像解像度（幅）
        height=320                  # 画像解像度（高さ）
    elif [ "${aspect}" = "1:2" ]; then 
        width=224                   # 画像解像度（幅）
        height=448                  # 画像解像度（高さ）
    elif [ "${aspect}" = "2:3" ]; then
        width=256                   # 画像解像度（幅）
        height=384                  # 画像解像度（高さ）
    else  # 9:16
        width=240                   # 画像解像度（幅）
        height=424                  # 画像解像度（高さ）
    fi
fi
echo "メモリ容量:" $(( ram / 1000 )) "解像度:" ${width} "x" ${height}

# 画像生成用プロンプト
humans=(
    "a ${nationality} masculine man with short hair, no makeup"
    "a ${nationality} woman"
    "a ${nationality} 20-year-old handsome guy with short hair, no makeup"
    "a ${nationality} 20-year-old girl"
    "a ${nationality} adult boy, with short hair, without makeup"
    "a ${nationality} women's university student, dark brown hair"
)
clothes=(
    "buisiness suit"
    "light business attire"
    "concierge uniform"
    "casual suit"
    "fashionable clothes"
    "casual clothes"
)
scenes=(
    "in a modern apartment"
    "in a office"
    "at a neutral view window side"
    "on a sidewalk"
    "in a sightseeng spot"
    "in a shipping mall"
)
humans_num=${#humans[*]}
clothes_num=${#clothes[*]}
scenes_num=${#scenes[*]}
prompts_n=$(( humans_num * clothes_num * scenes_num ))

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

echo "################################################################"
echo "古い webui.sh プロセスの終了処理を実行しています"
pids=`pgrep -f "webui.sh"`
if [ "${pids}" != "" ]; then
    echo "webui.sh（PID: $pids）を終了します。"
    kill ${pids} 2>/dev/null
    sleep 3
fi
pids=`pgrep -f "launch.py"`
if [ "${pids}" != "" ]; then
    echo "launch.py（PID: $pids）を終了します。"
    kill ${pids} 2>/dev/null
    sleep 3
fi
MY_PID=$$
# 自分以外の同じスクリプトのPIDをすべて取得してkill
OTHER_PIDS=$(pgrep -f "$app_name" )
OTHER_PIDS=$(echo $OTHER_PIDS | grep -v "^$MY_PID$")
if [ -n "$OTHER_PIDS" ]; then
    echo "自分以外の古いプロセス（PID: $OTHER_PIDS）を終了します。"
    echo "$OTHER_PIDS" | xargs kill -9 2>/dev/null
    sleep 3
fi
pids=`pgrep curl`
if [ "${pids}" != "" ]; then
    echo "古い curl プロセス（PID: $pids）を終了します。"
    kill ${pids} 2>/dev/null
    sleep 3
fi

# メイン設定処理
echo "################################################################"
echo "メイン設定処理を実行中... (PID: $MY_PID)"
~/stable-diffusion-webui/webui.sh &
echo "StableDiffusion の起動中... (約8秒～数分 メモリ速度による)"
i=8; sleep ${i}; while true; do
    i=$(( i + 1 ))
    res=$(curl -s -w "%{http_code}" "http://${api_url}/" 2>/dev/null
    )
    if [ "${res:(-3)}" = "200" ]; then
        echo "StableDiffusion の HTTP サーバーが起動しました"
        break
    fi
    echo "HTTPサーバー起動待機中 (${i} 秒経過) 応答:" ${res}
    sleep 1
done
i=0; sleep ${i}; while true; do
    i=$(( i + 1 ))
    curl -fsS "http://${api_url}/sdapi/v1/sd-models" > res.json 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "StableDiffusion の HTTP Web API が起動しました"
        echo "インストール済み画像生成モデル:"
        jq -r '.[] | (.model_name // .title // .name // empty)' res.json > sd_models.txt
        if [ $? -eq 0 ]; then
            cat sd_models.txt
            break
        fi
    fi
    echo "HTTP Web API 起動待機中 (${i} 秒経過)"
    sleep 1
done
res=`grep ${model} sd_models.txt`
if [ $? -ne 0 ] || [ "${res}" != "${model}" ]; then
    echo "[ERROR] モデル'${model}'が見つかりませんでした。"
    exit 1
fi

echo "################################################################"
echo "画像モデル設定中 =" ${model} "(約5秒～数分; メモリ速度による)"
i=5; sleep ${i}; while true; do
    i=$(( i + 1 ))
    res=$(curl -s -w "%{http_code}" -o res.json \
         -X POST "http://${api_url}/sdapi/v1/options" \
         -H "Content-Type: application/json" \
         -d "{\"sd_model_checkpoint\": \"${model}\"}"
    )
    if [ "${res:(-3)}" != "200" ]; then
        echo "[WARN] API - OPTIONS モデル設定時にエラーが発生しました (HTTP $http_code)"
        echo "レスポンス内容:"
        cat res.json 2>/dev/null || true
        exit 1
    else
        res=`curl -s "http://${api_url}/sdapi/v1/options" | jq -r '.sd_model_checkpoint' 2>/dev/null`
        res=`echo ${res} | cut -d"." -f1`
        if [ "${res}" = "${model}" ]; then
            break
        fi
    fi
    echo "画像モデル変更待機中 (${i} 秒経過) 応答:" ${res}
    sleep 1
done

echo "################################################################"
# メモリ使用量モニター・サブプロセス、仮想メモリの設定
( 
    rm -f memlog.csv
    while true; do
    echo -n `date -Iseconds`", " >> memlog.csv
    ps -o vsz,rss,pss,uss,command -C python --sort=-rss |grep launch.py |head -1 \
        |awk '{print $1",",$2",",$3",",$4}' >> memlog.csv
    sleep 2
    done
) &
child_pid=$!
echo "メモリ使用量モニターを起動しました (PID: $child_pid)"
if [ ${ram} -ge 16000 ]; then   # 16GB モデル
    swap_pct=`cat /proc/sys/vm/swappiness`
    sudo sh -c "echo 10 > /proc/sys/vm/swappiness"  # SDへのスワップ率を10%に設定
    trap 'kill $child_pid; sudo sh -c "echo $swap_pct>/proc/sys/vm/swappiness"' EXIT
else # 4GBモデル、8GBモデル
    trap 'kill $child_pid' EXIT
fi

echo "################################################################"
# 永久ループ 画像生成の繰り返し処理
echo "永久ループ 画像生成の繰り返し処理を実行中 (PID: $MY_PID)"
i=0; while true; do
    prompt=`get_prompt`
    #prompt="${prompts[i]}"
    seed=${RANDOM}
    echo -e "Prompt: \n"${prompt}
    echo "Stable Diffusion API: 画像生成中..." `date +"%H:%M:%S"`; SECONDS=0
    #output_file=${output_file_pfx}"_"`date +"%2d_%H%M"`".png"
    output_file=${output_dir}"/"${output_file_pfx}"_"`printf '%04x\n' $seed`".png"
    res=$(curl -s -w "%{http_code}" -o res.json \
      -X POST "http://${api_url}/sdapi/v1/txt2img" \
      -H "Content-Type: application/json" \
      -d "{
            \"prompt\": \"$prompt\",
            \"negative_prompt\": \"$NegativePrompt\",
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
    u_max=`awk -F, '{if($3>max){max=$3}}END{print int(max/1024+0.5) " MB"}' memlog.csv`
    u_avr=`awk -F, '{sum+=$3; count++} END{print int(sum/count/1024+0.5)" MB"}' memlog.csv`
    u_std=`awk -F, '{sum+=$3; sumsq+=$3*$3; count++} END{\
        mean=sum/count; print int(3*sqrt(sumsq/count - mean*mean)/1024+0.5)" MB"\
    }' memlog.csv`
    s_max=`awk -F, '{if($2>max){max=$2}}END{print int(max/1024+0.5) " MB"}' memlog.csv`
    s_avr=`awk -F, '{sum+=$2; count++} END{print int(sum/count/1024+0.5)" MB"}' memlog.csv`
    s_std=`awk -F, '{sum+=$2; sumsq+=$2*$2; count++} END{\
        mean=sum/count; print int(3*sqrt(sumsq/count - mean*mean)/1024+0.5)" MB"\
    }' memlog.csv`
    echo -n "メモリ使用量: 最大 =" ${u_max}
    echo -n "　　　　　　: 平均 =" ${u_avr}
    echo -n "　　　　　　: ３σ = " ${u_std}
    echo -n "メモリ確保量: 最大 =" ${s_max}
    echo -n "　　　　　　: 平均 =" ${s_avr}
    echo -n "　　　　　　: ３σ = " ${s_std}
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
        exiftool -overwrite_original\
            -ExposureTime=${SECONDS}\
            -UserComment="Memory Used: u_max= ${u_max} u_avr= ${u_avr} u_std = ${u_std} s_max= ${s_max} s_avr= ${s_avr} s_std = ${s_std}"\
            -Software="${app_name}"\
            "$output_file"
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
        sleep ${time_d}
    fi
    i=$((i+1))
    if [ $i -ge $prompts_n ]; then
        i=0
    fi
    echo "################################################################"
done

###############################################################################
# 参考文献 API資料
# http://localhost:7860/docs#/default/text2imgapi_sdapi_v1_txt2img_post
###############################################################################
# 便利コマンド 生成時間をファイルに保存し、最大値、最小値、平均値を求める
#   exiftool *.png|grep "Shutter Speed" | awk '{print $4 }' > time.csv
#   awk -F, '{if($1>max){max=$1}}END{print "max " max " 秒 (約 " int(max/60+0.5) "分)"}' time.csv
#   awk -F, 'BEGIN{min=9999}{if($1<min){min=$1}}END{print "min " min " 秒 (約 " int(min/60+0.5) "分)"}' time.csv
#   awk -F, '{sum+=$1; count++} END{avr=int(sum/count+0.5); print "avr " avr " 秒(約 " int(avr/60+0.5) "分)"}' time.csv
