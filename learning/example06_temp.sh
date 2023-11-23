#!/bin/bash
# Example 06 コンピュータの体温を測って表示してみよう

echo "Usage: "${0}                  # プログラム名を表示する

filename="/sys/class/thermal/thermal_zone0/temp" # 温度ファイル

temp=`cat ${filename}`              # ファイルの内容を変数tempに保持
temp=$(( $temp / 1000 ))            # 変数tempの値を1000で除算
echo "Temperature = "${temp}        # 温度を表示する
