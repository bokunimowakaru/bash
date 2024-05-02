#!/bin/bash
################################################################################
# HTTP サーバ + カメラ制御
#                                          Copyright (c) 2017-2024 Wataru KUNINO
################################################################################

IP=""                                   # 本機のIPアドレス
PORT=8080                               # 待ち受けポート番号

mkfifo payload
if [[ ${IP} = "" ]]; then IP=`hostname -I|cut -d" " -f1`; fi # IPアドレスを取得
HTML_HOME="HTTP/1.0 200 OK\nContent-Type: text/html\nConnection: close\n\n\
    <html>\n<head>\n<title>Camera</title>\n\
    <meta http-equiv=\"Content-type\" content=\"text/html; charset=UTF-8\">\
    \n</head>\n<body>\n<h3>Camera</h3>\n\
    <form method=\"GET\" action=\"http://"${IP}":"${PORT_HTTP}"/\">\n\
    Snap <input type=\"submit\" value=\"送信\">\n</form>\n</html>\n\n\
"                                       # HTTP + HTMLコンテンツ
HTML_JPG="HTTP/1.0 200 OK\nContent-Type: image/jpeg\nConnection: close\n\n"

# メイン処理部 #################################################################
echo "HTTP Server Started http://"${IP}":"${PORT}"/"    # アクセス用URL表示
while true; do                                          # HTTP待ち受け
    nc -lw1 -v 8080 < payload\
    |while read tcp; do
        DATE=`date "+%Y/%m/%d %R"`                      # 時刻を取得
        HTTP=`echo -E ${tcp}|cut -d"=" -f1`             # HTTPコマンドを抽出
        if [[ ${HTTP} = "GET /?" || ${HTTP} = "GET /?SNAP" ]]; then
            echo ${HTML_HOME} > payload
            libcamera-jpeg -o cam.jpg --width 320 --height 240
        elif [[ ${HTTP:0:13} = "GET /cam.jpg " ]]; then
            echo ${HTML_JPG} > payload
            cat cam.jpg >> payload
        fi
done; done                                              # 繰り返しここまで
