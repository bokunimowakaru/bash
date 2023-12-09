#!/usr/bin/env python3

###############################################################################
# Example 11 Lチカ BASIC [RPi.GPIO版]
###############################################################################
#
# 参考文献：
# https://github.com/bokunimowakaru/iot/blob/master/learning/example11_led_basic.py
#
#                   Copyright (c) 2019-2023 Wataru KUNINO https://bokunimo.net/
###############################################################################

port = 4                                # GPIO ポート番号
b = 0                                   # GPIO 出力値

from RPi import GPIO                    # ライブラリRPi内のGPIOモジュールの取得
from time import sleep                  # スリープ実行モジュールの取得
from sys import argv                    # 本プログラムの引数argvを取得

print(argv[0])                          # プログラム名を表示する
if len(argv) >= 2:                      # 引数があるとき
    port = int(argv[1])                 # GPIOポート番号をportへ

GPIO.setmode(GPIO.BCM)                  # ポート番号の指定方法の設定
GPIO.setwarnings(False)                 # ポート使用中などの警告表示を無効に
GPIO.setup(port, GPIO.OUT)              # ポート番号portのGPIOを出力に設定

while True:                             # 繰り返し処理
    b = int(not(b))                     # 変数bの値を論理反転
    print('GPIO'+str(port),'=',b)       # ポート番号と変数bの値を表示
    GPIO.output(port, b)                # 変数bの値をGPIO出力
    sleep(0.5)                          # 0.5秒間の待ち時間処理
