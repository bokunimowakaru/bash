#!/bin/bash
################################################################################
# HTTP サーバ + LED制御
#                                          Copyright (c) 2017-2024 Wataru KUNINO
################################################################################

IP=`hostname -I|cut -d" " -f1`          # 本機のIPアドレス
PORT=8080                               # 待ち受けポート番号
gpio_app="pinctrl"                      # GPIO制御に新しいpinctrlを使用する
# gpio_app="raspi-gpio"                 # GPIO制御に従来のraspi-gpioを使用する
ports=(17 27 22)                        # 赤,緑,青LED用 GPIOポート番号
d=("dl" "dh")                           # GPIOの論理値の定義

HTML="HTTP/1.0 200 OK\nContent-Type: text/html\nConnection: close\n\n<html>\n\
    <head>\n<title>COLOR LED</title>\n\
    <meta http-equiv=\"Content-type\" content=\"text/html; charset=UTF-8\">\n\
    </head>\n<body>\n<h3>COLOR LED</h3>\n\
    <form method=\"GET\" action=\"http://"${IP}":"${PORT}"/\">\n\
    Color Number = <input type=\"text\" size=\"1\" name=\"COLOR\" >(0~7)\n\
    <input type=\"submit\" value=\"送信\">\n</form>\n</html>\n\n\
"                                       # HTTP + HTMLコンテンツ

# メイン処理部 #################################################################
echo "HTTP Server Started http://"${IP}":"${PORT}"/"    # アクセス用URL表示
while true; do                                          # HTTP待ち受け
    echo -e $HTML\
    |nc -lw1 -v 8080\
    |while read tcp; do                                 # 受信データをtcpに代入
        DATE=`date "+%Y/%m/%d %R"`                      # 時刻を取得
        HTTP=`echo -E ${tcp}|cut -d"=" -f1`             # HTTPコマンドを抽出
        if [[ ${HTTP} = "GET /?COLOR" || ${HTTP} = "GET /?" ]]; then
            echo -E $DATE, ${tcp}                       # 取得日時とデータを表示
            color=`echo -E ${tcp}|cut -d"=" -f2|cut -d" " -f1` # 色値(0~7)を取得
            if [[ ${color} < 0 || ${color} > 7 ]]; then # 色の値が範囲外の時
                color=0                                 # LEDを消灯
            fi                                          # if文の終了
            for i in {0..2}; do                         # RGBの各LED色に対して
                port=${ports[${i}]}                     # GPIOポート番号を取得
                ${gpio_app} set ${port} op              # GPIOを出力に設定
                b=$(( (color >> i) & 1))                # LEDへの出力値を変数bへ
                ${gpio_app} "set" ${port} ${d[${b}]}    # GPIOに変数bの値を出力
            done                                        # LED用ループの終了
        fi
done; done                                              # 繰り返しここまで
