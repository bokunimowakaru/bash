#!/bin/bash
################################################################################
# HTTP サーバ + カメラ制御
#                                          Copyright (c) 2017-2024 Wataru KUNINO
################################################################################

IP=""                                   # 本機のIPアドレス
PORT=8080                               # 待ち受けポート番号

mkfifo payload_tx                       # HTTPデータ送信用のパイプを作成
trap "rm -f payload_tx || exit" SIGINT  # Ctrl-Cでパイプ切断し、プログラムを終了
if [[ ${IP} = "" ]]; then IP=`hostname -I|cut -d" " -f1`; fi # IPアドレスを取得
URL="http://"${IP}":"${PORT}
HTML="HTTP/1.0 200 OK\nContent-Type: text/html\nConnection: close\n\n<html>\n\
    <head>\n<title>Camera</title>\n\
    <meta http-equiv=\"Content-type\" content=\"text/html; charset=UTF-8\">\
    \n</head>\n<body>\n<h3>Camera</h3>\n\
    <p><form method=\"GET\" action=\""${URL}"/\">\n\
    Snap <input type=\"submit\" value=\"送信\">\n</form></p>\
    <p><a href=\""${URL}"/cam.jpg\">"${URL}"/cam.jpg</a></p></html>\n\n
"                                       # HTTP + HTMLコンテンツ
head="HTTP/1.0 200 OK\nContent-Type: image/jpeg\nContent-Length: LENGTH\n\"
error="HTTP/1.0 404 Not Found\n\n"

# HTTPリクエスト受信と、リクエストに応じたレスポンスを出力
payload_rx (){
    while read tcp; do
        HTTP=`echo -E ${tcp}|cut -d"=" -f1`             # HTTPコマンドを抽出
        if [[ ${HTTP:0:13} = "GET /cam.jpg " ]]; then
            LENGTH=`ls -l cam.jpg|cut -d" " -f5`
            echo -e ${head}|sed -e "s/LENGTH/${LENGTH}/g" > head.http
            cat head.http cam.jpg 
        elif [[ ${HTTP:0:6} = "GET / " ||  ${HTTP:0:7} = "GET /? " ]]; then
            echo -e ${HTML} 
            raspistill -n -o cam.jpg --width 320 --height 240
        elif [[ ${HTTP:0:5} = "GET /" ]]; then
            echo -e ${error}
            raspistill -n -o cam.jpg --width 320 --height 240
        fi
    done
}

# メイン処理部 #################################################################
while true; do                                              # 繰り返し処理
    echo "HTTP Server Started http://"${IP}":"${PORT}"/"    # アクセス用URL表示
    nc -lw1 -v 8080 < payload_tx| payload_rx > payload_tx   # HTTP待ち受け
done                                                        # 繰り返しここまで
