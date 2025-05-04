#!/bin/bash
###############################################################################
# I2C温度センサ の温度と湿度を送信する
# 
# センサ：Sensirion SHT40,SHT41,SHT45
# 送信先1：Ambient HTTP POST方式 (https://ambidata.io/)
# 送信先2：LAN CSVxUDP方式 (https://bokunimo.net/iot/CSVxUDP/)
#
#                   Copyright (c) 2016-2025 Wataru KUNINO https://bokunimo.net/
###############################################################################

channelId=100                                           # AmbientチャネルID
writeKey="0123456789abcdef"                             # Ambientライトキー
udp_port=1024                                           # CSVxUDP ポート番号
device="humid_1"                                        # CSVxUDP デバイス名

url="http://ambidata.io"                                # 送信先アドレス
udp_app="../tools/udp_sender.py"                        # UDP送信プログラム
sht4_app="../gpio/sht4-bsd3clause/sht4x_i2c"            # SHT4xの読み取り
interval=30                                             # 測定間隔(30秒以上)

while true;do                                           # 永久に繰り返し
    data=`${sht4_app}`
    temp=(`echo "${data}"|grep "a_temperature"`)
    humi=(`echo "${data}"|grep "a_humidity"`)
    echo "Temperature = ${temp[1]}"                     # 温度測定結果の表示
    echo "Humidity = ${humi[1]}"                        # 温度測定結果の表示
    data="\"d1\":${temp[1]},\"d2\":${humi[1]}"          # データ生成
    echo "{"${data}"}"
    if [[ ${channelId} -ne 100 ]]; then
        json="{\"writeKey\":\"${writeKey}\",${data}}"   # JSON用のデータを生成
        curl -s "${url}/api/v2/channels/${channelId}/data"\
             -X POST -H "Content-Type: application/json" -d ${json} # HTTP送信
    fi
    echo ${device}","${temp[1]}", "${humi[1]}|${udp_app} ${udp_port} # UDP送信
    sleep ${interval}                                   # 測定間隔の待ち時間
done                                                    # 繰り返し
exit 0

###############################################################################
実行例：
pi@raspberrypi:~/bash/learning $ ./example22_sht4.sh
Temperature = 21.4
Humidity = 70.4
{"d1":21.4,"d2":70.4}
UDP Sender (usage: ../tools/udp_sender.py port < data)
send : humid_9,21.4, 70.4
Temperature = 21.3
Humidity = 72.0
{"d1":21.3,"d2":72.0}
UDP Sender (usage: ../tools/udp_sender.py port < data)
send : humid_9,21.3, 72.0
###############################################################################
