#!/usr/bin/env python3
###############################################################################
# Example 13 チャイム [RPi.GPIO版]
###############################################################################
#
# 参考文献：
# https://github.com/bokunimowakaru/iot/blob/master/learning/example13_chime.py
#
#                   Copyright (c) 2019-2023 Wataru KUNINO https://bokunimo.net/
###############################################################################

port = 4                                # チャイム用 GPIO ポート番号
ping_f = 554                            # チャイム音の周波数1
pong_f = 440                            # チャイム音の周波数2

from RPi import GPIO                    # GPIOモジュールの取得
from time import sleep                  # スリープ実行モジュールの取得
from sys import argv                    # 本プログラムの引数argvを取得

def chime():                            # チャイム（スレッド用）
    pwm.ChangeFrequency(ping_f)         # PWM周波数の変更
    pwm.start(50)                       # PWM出力を開始。デューティ50％
    sleep(0.5)                          # 0.5秒の待ち時間処理
    pwm.ChangeFrequency(pong_f)         # PWM周波数の変更
    sleep(0.5)                          # 0.5秒の待ち時間処理
    pwm.stop()                          # PWM出力停止

print(argv[0])                          # プログラム名を表示する
if len(argv) >= 2:                      # 引数があるとき
    port = int(argv[1])                 # GPIOポート番号をportへ
GPIO.setmode(GPIO.BCM)                  # ポート番号の指定方法の設定
GPIO.setup(port, GPIO.OUT)              # ポート番号portを出力に

pwm = GPIO.PWM(port, ping_f)            # PWM出力用のインスタンスを生成
chime()                                 # チャイム音
sleep(0.1)                              # 0.1秒間の待ち時間処理
GPIO.cleanup(port)                      # GPIOを未使用状態に戻す
