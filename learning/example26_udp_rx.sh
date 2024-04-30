#!/bin/bash
# UDP Reciever

################################################################################
# 下記のコマンドを実行してNetcatをインストールしてください
# sudo apt install netcat-openbsd
################################################################################

echo "Usage: "${0}" [udp port (1024~65535)]" # プログラム名と使い方を表示する
PORT=1024                                   # UDP待ち受けポート番号
if [[ ${#} -ge 1 ]]; then
    PORT=$1
fi
echo "Listening UDP port "${PORT}"..."      # ポート番号表示

while true; do                              # 永久ループ
    UDP=`nc -luw0 ${PORT}`                  # UDPパケットを取得
    DATE=`date "+%Y/%m/%d %R"`              # 日時を取得
    echo -E ${DATE}, ${UDP}                 # 取得日時とデータを表示
done                                        # 永久ループを繰り返す
