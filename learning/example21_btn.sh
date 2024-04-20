#!/bin/bash
###############################################################################
# ボタン状態を送信する
#
# 参考文献 raspi-gpio help
#
#                   Copyright (c) 2023-2024 Wataru KUNINO https://bokunimo.net/
###############################################################################

line_token="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # LINEで取得したTOKEN
url_s="https://notify-api.line.me/api/notify"            # LINE Notify のURL
    # 'Authorization':'Bearer ' + line_token
    # 'Content-Type':'application/x-www-form-urlencoded; charset=UTF-8'
udp_port=1024                                           # CSVxUDP ポート番号
device="btn_s_1"                                        # CSVxUDP デバイス名

udp_app="../tools/udp_sender.py"                        # UDP送信プログラム
gpio_app="pinctrl"                          # GPIO制御にpinctrlを使用する
# gpio_app="raspi-gpio"                     # GPIO制御にraspi-gpioを使用する

# LINE送信用の関数line_notify()定義部
line_notify() {                             # メッセージ送信用の関数
    time=`date "+%Y/%m/%d %R"`              # 現在の日時を取得する
    message="${1}(${time})"                 # 引き数と日時を連結する
    res=`curl -s -m3 -XPOST\
         -H "Authorization:Bearer ${line_token}"\
         -d "message=${1}(${time})"\
         ${url_s}`                          # LINEにメッセージを送信する
    if [[ ${res} ]]; then                   # 応答があった場合
        echo ${message}" -> "${res}         # 送信メッセージと応答を表示する
    else                                    # 応答が無かった場合
        echo "ERROR"                        # ERRORを表示
    fi                                      # ifの終了
}

# 主要処理部
echo "Usage: "${0}                          # プログラム名と使い方を表示する
port=26                                     # GPIO ポート番号
${gpio_app} "set" ${port} "ip"              # ポート番号portのGPIOを入力に設定
${gpio_app} "set" ${port} "pu"              # ポート番号portをプルアップ
prev=0                                      # 前回値を保持する変数prev

while true; do                              # 永久ループ
    btn=`${gpio_app} get ${port}`           # ボタン状態を取得
    if [[ ${btn:15:2} = "lo" ]]; then       # 入力値がLレベルの時
        val=0                               # 変数valに0を代入
    elif [[ ${btn:15:2} = "hi" ]]; then     # 入力値がHレベルの時
        val=1                               # 変数valに1を代入
    else                                    # その他の場合(raspi-gpioなど)
        val=`echo ${btn}|tr " " "\n"|grep "level="` # ボタンレベル値を取得
        val=${val:6:1}                      # レベル値を抽出
        if [[ ${val} = "" ]]; then          # レベル値が得られなかったとき
            val=0                           # 変数valに0を代入
        fi
    fi
    val=$(( ! ${val} ))                     # 変数valの論理を反転
    if [[ ${val} -ne ${prev} ]]; then       # 変数valの値が前回と異なる時
        echo ${device}","${val}|${udp_app} ${udp_port}  # CSVxUDP送信
        if [[ ${val} == 1 ]]; then          # ボタンが押されていた時
            line_notify "ボタンが押されました"
        fi
        prev=${val}                         # 変数valの値を変数prevに保持
    fi
    sleep 0.2                               # 0.2秒間の待ち時間処理
done
