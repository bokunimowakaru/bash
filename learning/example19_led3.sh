#!/bin/bash
# Example 19 カラー Lチカ
# 参考文献 raspi-gpio help

gpio_app="pinctrl"                      # GPIO制御に新しいpinctrlを使用する
# gpio_app="../gpio/gpio_zero.sh"       # GPIO制御に標準のgpio_zero.shを使用する
# gpio_app="raspi-gpio"                 # GPIO制御に従来のraspi-gpioを使用する

port_R=17                               # 赤色LED用 GPIO ポート番号
port_G=27                               # 緑色LED用 GPIO ポート番号
port_B=22                               # 青色LED用 GPIO ポート番号
ports=(${port_R} ${port_G} ${port_B})   # ポート番号の配列化
d=("dl" "dh")                           # GPIOの論理値の定義
color=0                                 # 色番号0～7

# 主要処理部
echo "Usage: "${0}" <color>"            # プログラム名と使い方を表示する
echo "       echo <color>|"${0}         # 標準入力にも対応
if [[ ${#} == 0 ]]; then                # 取得した引数が0個のとき
    read color                          # 標準入力から色を代入
else                                    # 引数が存在するとき
    color=${1}                          # 入力パラメータから色を代入
fi                                      # if文の終了
if [[ ${color} < 0 || ${color} > 7 ]]; then # 色の値が範囲外の時
    echo "ERROR: out of range 0-7"      # エラー表示
    exit 1                              # 終了
fi                                      # if文の終了
for i in {0..2}; do                     # RGBの各LED色に対して
    port=${ports[${i}]}                 # ポート番号を取得
    ${gpio_app} set ${port} op          # ポート番号portのGPIOを出力に設定
    b=$(( (color >> i) & 1))            # 該当LEDへの出力値を変数bへ
    # echo "GPIO"${port}"="${b}         # ポート番号と変数bの値を表示
    ${gpio_app} "set" ${port} ${d[${b}]} # GPIOに変数bの値を出力
done                                    # ループの終了
if [[ ${gpio_app} = "../gpio/gpio_zero.sh" ]]; then
    ${gpio_app} quit > /dev/null        # GPIO用のHTTPサーバを停止する
fi
exit                                    # プログラムの終了
