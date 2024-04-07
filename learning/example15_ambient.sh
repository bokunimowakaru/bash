#!/bin/bash
###############################################################################
# Ambient(https://ambidata.io/)とLAN内へ Raspberry Piの温度データを送信する
#
# 送信先1：Ambient HTTP POST方式 (https://ambidata.io/)
# 送信先2：LAN CSVxUDP方式 (https://bokunimo.net/iot/CSVxUDP/)
#
#                   Copyright (c) 2016-2023 Wataru KUNINO https://bokunimo.net/
###############################################################################

channelId=100               #要設定                     # AmbientチャネルID
writeKey="0123456789abcdef" #要設定                     # Ambientライトキー
udp_port=1024                                           # CSVxUDP ポート番号
device="temp0_1"                                        # CSVxUDP デバイス名

url="http://ambidata.io"                                # 送信先アドレス
sensor="/sys/devices/virtual/thermal/thermal_zone0/temp" # CPUの温度センサ
udp_app="../tools/udp_sender.py"                        # UDP送信プログラム
temp_offset=25                                          # CPUの温度上昇値
interval=30                                             # 測定間隔(30秒以上)

while true;do                                           # 永久に繰り返し
    temp=`cat ${sensor}`                                # 温度を取得
    temp=$((temp / 100 - temp_offset * 10))             # 温度に変換(10倍値)
    int=$((temp / 10))                                  # 整数部
    dec=$((temp - int * 10))                            # 小数部
    echo "Temperature = ${int}.${dec}"                  # 温度測定結果の表示
    data="\"d1\":\"${int}.${dec}\""                     # データ生成
    json="{\"writeKey\":\"${writeKey}\",${data}}"       # JSON用のデータを生成
    curl -s "${url}/api/v2/channels/${channelId}/data"\
         -X POST -H "Content-Type: application/json" -d ${json} # Ambient送信
    # echo ${device}","${int}.${dec}|${udp_app} ${udp_port}  # CSVxUDP送信
    sleep ${interval}                                   # 測定間隔の待ち時間
done                                                    # 繰り返し

###############################################################################
#
# (参考資料)
# Ambientでの公開データ：
# https://ambidata.io/bd/board.html?id=128
# Gitリポジトリ：
# https://goo.gl/i4raOx
# 筆者ブログページ：
# https://bokunimo.net/blog/raspberry-pi/126/
