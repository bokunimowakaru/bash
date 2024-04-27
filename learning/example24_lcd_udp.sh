#!/bin/bash
# I2C LCD UDP Monitor

################################################################################
# 元ソース：
# https://github.com/bokunimowakaru/raspi_lcd/blob/master/example_Pi5.sh
# https://github.com/bokunimowakaru/raspi_lcd/blob/master/raspi_i2c.c
# https://github.com/bokunimowakaru/raspi_lcd/blob/master/example.sh
################################################################################
# 下記のコマンドを実行してNetcatをインストールしてください
# sudo apt install netcat-openbsd
################################################################################

echo "Usage: "${0}" [udp port (1024~65535)]" # プログラム名と使い方を表示する
gpio_app="pinctrl"              # GPIO制御にpinctrlを使用する for Raspberry Pi 5
LCD_IO=4                        # LCDリセット用IOポート番号を設定する
PORT=1024                       # UDP待ち受けポート番号

# LCD初期化処理
${gpio_app} set ${LCD_IO} op    # ポート番号portのGPIOを出力に設定
${gpio_app} set ${LCD_IO} dl    # GPIOにLレベルを出力
sleep 0.1                       # 0.1秒の待ち時間処理
${gpio_app} set ${LCD_IO} dh    # GPIOにHレベルを出力
sleep 0.1                       # 0.1秒の待ち時間処理
i2cset -y  1 0x3e 0x00 0x39  0x14  0x73 0x56 0x6c 0x38 0x0C i
sleep 0.1                       # 0.1秒の待ち時間処理

if [[ ${#} -ge 1 ]]; then
    PORT=$1
fi

# LCD表示用データ作成
echo "Listening UDP port "${PORT}"..."          # ポート番号表示
UDP="Listen  "${PORT}"..."                      # UDP受信用変数を定義

while true; do                                  # 永久ループ
    s1=${UDP:0:8}                               # 受信データの先頭8バイト
    s2=${UDP:8:10}                              # 9バイト目以降10バイトを抽出
    hex1=`echo -n ${s1}| iconv -f utf8 -t sjis | od -An -tx1 | sed 's/ / 0x/g'`
    hex2=`echo -n ${s2}| iconv -f utf8 -t sjis | od -An -tx1 | sed 's/ / 0x/g'`
    i2cset -y  1 0x3e 0x00 0x80 i
    i2cset -y  1 0x3e 0x40 ${hex1} 0x20 0x20 0x20 0x20 0x20 0x20 0x20 0x20 i
    i2cset -y  1 0x3e 0x00 0xc0 i
    i2cset -y  1 0x3e 0x40 ${hex2} 0x20 0x20 0x20 0x20 0x20 0x20 0x20 0x20 i
    UDP=`nc -luw0 ${PORT}`                      # UDPパケットを取得
    DATE=`date "+%Y/%m/%d %R"`                  # 日時を取得
    echo -E $DATE, $UDP                         # 取得日時とデータを表示
done                                            # 永久ループを繰り返す
