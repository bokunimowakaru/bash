#!/bin/bash
###############################################################################
# ボタン状態を送信する
#
# 送信先1：LINE Notify HTTP POST方式 (https://notify-bot.line.me/ja/)
# 送信先2：LAN CSVxUDP方式 (https://bokunimo.net/iot/CSVxUDP/)
#
# 参考文献 raspi-gpio help
#
#                   Copyright (c) 2023-2025 Wataru KUNINO https://bokunimo.net/
###############################################################################

line_ch_id="0000000000"                         # LINEで取得した Channel ID
line_ch_pw="00000000000000000000000000000000"   # LINEで取得した Channel secret
url_s="https://api.line.me/"                    # LINE Messaging API のURL
udp_port=1024                                   # CSVxUDP ポート番号
device="btn_s_1"                                # CSVxUDP デバイス名
udp_app="../tools/udp_sender.py"                # UDP送信プログラム

gpio_app="pinctrl"                              # GPIO制御にpinctrlを使用
# gpio_app="raspi-gpio"                         # GPIO制御にraspi-gpioを使用

# LINE Messaging API用の Token の取得部
get_line_token(){
    res=`curl -s -m3 -XPOST \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode 'grant_type=client_credentials' \
        --data-urlencode 'client_id='${line_ch_id} \
        --data-urlencode 'client_secret='${line_ch_pw}\
         ${url_s}oauth2/v3/token`               # LINEからTokenを取得する
    echo $res|tr "," "\n"|grep "access_token"|tr ":" " "|awk '{print $2}'|tr -d '"'
}

# LINE送信用の関数line_notify()定義部
line_notify() {                                 # メッセージ送信用の関数
    time=`date "+%Y/%m/%d %R"`                  # 現在の日時を取得する
    line_token="${1}"                           # LINE Token を代入
    message="[raspi] ${2} (${time})"            # 引き数と日時を連結する
    # echo ${line_token}    ## デバッグ用 ##
    json='{"messages":[{"type":"text","text":"'${message}'"}]}'
    # echo ${json}          ## デバッグ用 ##
    res=`curl -s -m3 -XPOST \
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer '${line_token} \
        -d "${json}" \
        ${url_s}v2/bot/message/broadcast`       # LINEにメッセージを送信する
    if [[ ${res} ]]; then                       # 応答があった場合
        if [[ ${res} == "{}" ]]; then           # メッセージが無かった場合
            echo ${message}" -> OK "            # 送信メッセージとOKを表示する
        else                                    # メッセージが存在した場合
            echo ${message}" -> "${res}         # 送信メッセージと応答を表示する
        fi
    else                                        # 応答が無かった場合
        echo "ERROR"                            # ERRORを表示
    fi                                          # ifの終了
}

# 主要処理部
echo "Usage: "${0}                          # プログラム名と使い方を表示する
port=26                                     # GPIO ポート番号
${gpio_app} "set" ${port} "ip"              # ポート番号portのGPIOを入力に設定
${gpio_app} "set" ${port} "pu"              # ポート番号portをプルアップ
prev=0                                      # 前回値を保持する変数prev

while true; do                              # 永久ループ
    btn=`${gpio_app} get ${port}`           # ボタン状態を取得
    if [[ ${btn:15:2} == "lo" ]]; then      # 入力値がLレベルの時
        val=0                               # 変数valに0を代入
    elif [[ ${btn:15:2} == "hi" ]]; then    # 入力値がHレベルの時
        val=1                               # 変数valに1を代入
    else                                    # その他の場合(raspi-gpioなど)
        val=`echo ${btn}|tr " " "\n"|grep "level="` # ボタンレベル値を取得
        val=${val:6:1}                      # レベル値を抽出
        if [[ ${val} == "" ]]; then         # レベル値が得られなかったとき
            val=0                           # 変数valに0を代入
        fi
    fi
    val=$(( ! ${val} ))                     # 変数valの論理を反転
    if [[ ${val} -ne ${prev} ]]; then       # 変数valの値が前回と異なる時
        echo ${device}","${val}|${udp_app} ${udp_port}  # CSVxUDP送信
        if [[ ${val} == 1 ]]; then          # ボタンが押されていた時
            token=`get_line_token`          # LINE Token を取得
            line_notify "${token}" "ボタンが押されました"   # LINEに送信
        fi
        prev=${val}                         # 変数valの値を変数prevに保持
    fi
    sleep 0.2                               # 0.2秒間の待ち時間処理
done
