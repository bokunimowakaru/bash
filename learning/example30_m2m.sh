#!/bin/bash
# ホームサーバ

PORT_UDP=1024                           # UDP待ち受けポート番号
PORT_HTTP=8080                          # HTTP待ち受けポート番号
HTTP_IP=`hostname -I|cut -d" " -f1`":"${PORT_HTTP} # 本機のIPアドレスを取得
CAMERA_IP="127.0.0.1:8081"              # カメラのIPアドレス+ポート番号
CHIME_IP="127.0.0.1:8082"               # 圧電サウンダのIPアドレス+ポート番号
LOG="log.csv"                           # 保存するログファイル名
PICT=~/Pictures/camera/                 # カメラで撮影した写真の保存用フォルダ

html (){
    echo -e "HTTP/1.0 200 OK\nContent-Type: text/html\nConnection: close\n"
    echo -e "<html>\n<head>\n<title>Home M2M Server</title>"
    echo -e "<meta http-equiv=\"refresh\" content=\"20\";URL=http://${HTTP_IP}/\">"
    echo -e "<meta http-equiv=\"Content-type\" content=\"text/html; charset=UTF-8\">"
    echo -e "</head>\n<body>\n<h3>Home M2M Server</h3>"
    echo -n "<p>UDP Data Log:<br><pre>"
    tail -10 ${1}
    echo -e "</pre></p>"
    echo -e "<p>Door Bell: <a href=\"http://${CHIME_IP}/\">http://${CHIME_IP}/</a></p>"
    echo -e "<p>Camera: <a href=\"http://${CAMERA_IP}/\">http://${CAMERA_IP}/</a></p>"
    echo -e "</html>\n"
}

# HTTPサーバ実行部 #############################################################
if [[ ${1} == "http_srv" ]]; then       # HTTPサーバの起動指示があった時
    echo `date` "Started Subprocess http_srv"
    while true; do                                      # HTTP待ち受け
        html ${LOG}|nc -lw1 -v ${PORT_HTTP}|grep "^GET" # HTMLデータの送信
    done                                                # 繰り返しここまで
fi

echo `date "+%Y/%m/%d %R"`", started"| tee -a ${LOG}    # 起動時刻をログに保存
mkdir -p ${PICT}                                        # 写真保存用フォルダ作成
${0} http_srv &                                         # HTTPサーバを起動する
echo "HTTP Server http://"${HTTP_IP}"/"                 # アクセス用URL表示
trap "kill `pidof -x ${0}`;kill `pidof nc`" EXIT SIGINT # Ctrl-CでHTTPを終了する

# HTTPクライアント部(カメラ撮影) ###############################################
camera (){
    curl "http://"${CAMERA_IP}"/"                       # 写真撮影
    sleep 5                                             # 撮影完了待ち
    pict=${PICT}`date +"%y%m%d%H%M%S"`.jpg              # 写真のファイル名
    curl "http://"${CAMERA_IP}"/cam.jpg" -o ${pict}     # 写真を取得して保存
}

# メイン処理部 #################################################################
echo "Listening UDP port "${PORT_UDP}"..."              # ポート番号表示
while true; do                                          # 永久ループ
    UDP=`nc -luw0 ${PORT_UDP}`                          # UDPパケットを取得
    echo -E `date "+%Y/%m/%d %R"`, ${UDP}| tee -a ${LOG} # 取得データの保存
    if [[ ${UDP} = "btn_s_1,1" || ${UDP} = "pir_s_1,1" ]]; then # ボタン押下時
        camera &                                        # カメラ撮影の実行
    fi
done                                                    # 永久ループを繰り返す
