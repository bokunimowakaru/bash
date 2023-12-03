#!/bin/bash
# Example 18 Lチカ BASIC
# 参考文献 raspi-gpio help

echo "Usage: [echo names... |] "${0}    # プログラム名と使い方を表示する
gpio_app="raspi-gpio"                   # GPIO制御に標準のraspi-gpioを使用する

port=4                                  # GPIO ポート番号
b=0                                     # GPIO 出力値
${gpio_app} set ${port} op              # ポート番号portのGPIOを出力に設定

while true; do                          # 永久ループ
    echo "GPIO"${port}"="${b}           # ポート番号と変数bの値を表示
    if [[ ${b} == 0 ]]; then            # b＝0のとき
        ${gpio_app} set ${port} dl      # GPIOにLレベル(約0V)を出力
    else                                # b≠0(b=1)のとき
        ${gpio_app} set ${port} dh      # GPIOにHレベル(約3.3V)を出力
    fi                                  # if文の終了
    sleep 0.5                           # 0.5秒間の待ち時間処理
    b=$((!b))                           # 変数bの値を論理反転
done
