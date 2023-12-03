#!/bin/bash
# Example 19 カラー Lチカ
# 参考文献 raspi-gpio help

echo "Usage: "${0}" <color>"            # プログラム名と使い方を表示する
echo "       echo <color>|"${0}         # 標準入力にも対応

gpio_app="raspi-gpio"                   # GPIO制御に標準のraspi-gpioを使用する
port_R=17                               # 赤色LED用 GPIO ポート番号
port_G=27                               # 緑色LED用 GPIO ポート番号
port_B=22                               # 青色LED用 GPIO ポート番号
ports=(${port_R} ${port_G} ${port_B})   # ポート番号の配列化
color=0                                 # 色番号0～7

if [[ ${#} == 0 ]]; then                # 取得した引数が0個のとき
    read color                          # 標準入力から色を代入
else                                    # 引数が存在するとき
    color=${1}                          # 入力パラメータから色を代入
fi                                      # if文の終了
if [[ ${color} -ge 0 && ${color} -le 7 ]]; then # 色が代入されていた時
    for i in {0..2}; do                 # RGBの各LED色に対して
        port=${ports[${i}]}             # ポート番号を取得
        ${gpio_app} set ${port} op      # ポート番号portのGPIOを出力に設定
        b=$(( (color >> i) & 1))        # 該当LEDへの出力値を変数bへ
        echo "GPIO"${port}"="${b}       # ポート番号と変数bの値を表示
        if [[ ${b} == 0 ]]; then        # b＝0のとき
            ${gpio_app} set ${port} dl  # GPIOにLレベル(約0V)を出力
        else                            # b≠0(b=1)のとき
            ${gpio_app} set ${port} dh  # GPIOにHレベル(約3.3V)を出力
        fi                              # if文の終了
    done                                # ループの終了
fi                                      # if文の終了
exit                                    # プログラムの終了
