
#!/bin/bash
###############################################################################
# 人感センサの検出状態をCSVxUDPで送信する
#
# 送信先1：LINE Notify HTTP POST方式 (https://notify-bot.line.me/ja/)
#
# 参考文献 raspi-gpio help
#
#                   Copyright (c) 2023-2024 Wataru KUNINO https://bokunimo.net/
###############################################################################

udp_port=1024                                           # CSVxUDP ポート番号
device="pir_s_1"                                        # CSVxUDP デバイス名

udp_app="../tools/udp_sender.py"                        # UDP送信プログラム
gpio_app="pinctrl"                          # GPIO制御にpinctrlを使用する
# gpio_app="raspi-gpio"                     # GPIO制御にraspi-gpioを使用する

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
    # val=$(( ! ${val} ))                   # PIRセンサは論理反転が不要
    if [[ ${val} -ne ${prev} ]]; then       # 変数valの値が前回と異なる時
        echo ${device}","${val}|${udp_app} ${udp_port}  # CSVxUDP送信
        prev=${val}                         # 変数valの値を変数prevに保持
    fi
    sleep 0.2                               # 0.2秒間の待ち時間処理
done
