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
gpio_app="pinctrl"                      # GPIO制御に新しいpinctrlを使用する
# gpio_app="../gpio/gpio_zero.sh"       # GPIO制御に標準のgpio_zero.shを使用する
# gpio_app="raspi-gpio"                 # GPIO制御に従来のraspi-gpioを使用する
if [[ ${gpio_app} = "../gpio/gpio_zero.sh" ]]; then
   trap "${gpio_app} quit" EXIT         # 終了時にGPIO用のHTTPサーバを停止する
fi

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
echo "Usage: "${0}                      # プログラム名と使い方を表示する
port=4                                  # GPIO ポート番号
${gpio_app} "set" ${port} "ip"          # ポート番号portのGPIOを入力に設定
b=0                                     # 前回値を保持

while true; do                          # 永久ループ
    btn=`${gpio_app} get ${port}`       # ボタン状態を取得
    val=`echo ${btn}|tr " " "\n"|grep "level="` # ボタンレベル値を取得
    val=${val:6:1}                      # レベル値を抽出
    if [[ ${val} && ${val} -ne ${b} ]]; then
        b=${val}
        echo ${device}","${b}|${udp_app} ${udp_port}  # CSVxUDP送信
        if [[ ${b} = 1 ]]; then
            line_notify "ボタンが押されました"
        fi
    fi
    sleep 0.2                           # 0.1秒間の待ち時間処理
done
