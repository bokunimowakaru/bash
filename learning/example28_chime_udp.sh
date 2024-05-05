#!/bin/bash
################################################################################
# HTTP サーバ + 圧電サウンダ制御
#                                          Copyright (c) 2017-2024 Wataru KUNINO
################################################################################

IP=""                                   # 本機のIPアドレス
PORT_UDP=1024                           # UDP待ち受けポート番号
PORT_HTTP=8080                          # HTTP待ち受けポート番号
chime_app="../gpio/chime_zero.py"       # チャイム音の駆動にchime_zero.pyを使用
port=4                                  # 圧電スピーカを接続するGPIO ポート番号

# HTTPサーバ実行部 #############################################################
if [[ ${1} == "http_srv" ]]; then       # HTTPサーバの起動指示があった時
    echo `date` "Started Subprocess http_srv"
    if [[ ${IP} = "" ]]; then IP=`hostname -I|cut -d" " -f1`; fi # IPアドレス
    HTML="HTTP/1.0 200 OK\nContent-Type: text/html\nConnection: close\n\n\
        <html>\n<head>\n<title>Chime</title>\n\
        <meta http-equiv=\"Content-type\" content=\"text/html; charset=UTF-8\">\
        \n</head>\n<body>\n<h3>Chime</h3>\n\
        <form method=\"GET\" action=\"http://"${IP}":"${PORT_HTTP}"/\">\n\
        Ring <input type=\"submit\" value=\"送信\">\n</form>\n</html>\n\n\
    "                                   # HTTP + HTMLコンテンツ
    while true; do                                      # HTTP待ち受け
        echo -e $HTML\
        |nc -lw1 -v ${PORT_HTTP}\
        |while read tcp; do                             # 受信データをtcpに代入
            HTTP=`echo -E ${tcp}|cut -d"=" -f1`         # HTTPコマンドを抽出
            if [[ ${HTTP} = "GET /?" || ${HTTP} = "GET /?BELL" ]]; then
                echo -E `date "+%Y/%m/%d %R"`, ${tcp}   # 取得日時とデータを表示
                ${chime_app} ${port}                    # チャイム音を鳴らす
            fi
    done; done                                          # 繰り返しここまで
fi

${0} http_srv &                                         # HTTPサーバを起動する
echo "HTTP Server Started http://"${IP}":"${PORT_HTTP}"/" # アクセス用URL表示
trap "kill `pidof -x ${0}`" SIGINT          # Ctrl-CでHTTPサーバを終了する

# メイン処理部 #################################################################

echo "Listening UDP port "${PORT_UDP}"..."  # ポート番号表示
while true; do                              # 永久ループ
    UDP=`nc -luw0 ${PORT_UDP}`              # UDPパケットを取得
    echo -E `date "+%Y/%m/%d %R"`, ${UDP}   # 取得日時とデータを表示
    if [[ ${UDP} = "btn_s_1,1" || ${UDP} = "pir_s_1,1" ]]; then # ボタン押下時
        ${chime_app} ${port}                # チャイム音を鳴らす
    fi
done                                        # 永久ループを繰り返す
