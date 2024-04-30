#!/bin/bash
###############################################################################
# LAN内に Raspberry Piの温度データを送信する
#
# 送信先：LAN CSVxUDP方式 (https://bokunimo.net/iot/CSVxUDP/)
#
#                   Copyright (c) 2016-2023 Wataru KUNINO https://bokunimo.net/
###############################################################################

udp_port=1024                                           # CSVxUDP ポート番号
device="temp0_1"                                        # CSVxUDP デバイス名

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
    echo ${device}","${int}.${dec}|${udp_app} ${udp_port}  # CSVxUDP送信
    sleep ${interval}                                   # 測定間隔の待ち時間
done                                                    # 繰り返し

###############################################################################
#
# (参考資料)
# Gitリポジトリ：
# https://goo.gl/i4raOx
# 筆者ブログページ：
# https://bokunimo.net/blog/raspberry-pi/126/
