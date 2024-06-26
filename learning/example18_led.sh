#!/bin/bash
# Example 18 Lチカ BASIC
# 参考文献 raspi-gpio help

gpio_app="pinctrl"                      # GPIO制御にpinctrlを使用する
# gpio_app="../gpio/gpio_zero.sh"       # GPIO制御にgpio_zero.shを使用する
# gpio_app="raspi-gpio"                 # GPIO制御に従来のraspi-gpioを使用する
if [[ ${gpio_app} == "../gpio/gpio_zero.sh" ]]; then
   trap "${gpio_app} quit" EXIT SIGINT  # 終了時にGPIO用のHTTPサーバを停止する
fi

# 主要処理部
echo "Usage: "${0}                      # プログラム名と使い方を表示する
port=4                                  # GPIO ポート番号
b=0                                     # GPIO 出力値
${gpio_app} set ${port} op              # ポート番号portのGPIOを出力に設定
d=("dl" "dh")                           # GPIOの論理値の定義
while true; do                          # 永久ループ
    echo "GPIO"${port}"="${b}           # ポート番号と変数bの値を表示
    ${gpio_app} "set" ${port} ${d[${b}]}  # GPIOに変数bの値を出力
    sleep 0.5                           # 0.5秒間の待ち時間処理
    b=$((!b))                           # 変数bの値を論理反転
done
