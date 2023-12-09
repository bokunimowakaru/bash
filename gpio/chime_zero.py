#!/usr/bin/env python3
###############################################################################
# Example 13 チャイム [GPIO Zero 版]
###############################################################################
#
# 参考文献：
# https://github.com/bokunimowakaru/iot/blob/master/learning/example13_chime.py
# https://gpiozero.readthedocs.io/
#
#                   Copyright (c) 2019-2023 Wataru KUNINO https://bokunimo.net/
###############################################################################

port = 4                                # チャイム用 GPIO ポート番号
ping_f = 'C5'                           # チャイム音の周波数1
pong_f = 'A4'                           # チャイム音の周波数2

from gpiozero import TonalBuzzer        # GPIO Zero のTonalBuzzerを取得
from gpiozero.tones import Tone         # GPIO Zero のToneを取得
from time import sleep                  # スリープ実行モジュールの取得
from sys import argv                    # 本プログラムの引数argvを取得

def chime():                            # チャイム（スレッド用）
    pwm.play(Tone(ping_f))              # PWM周波数の変更
    sleep(0.5)                          # 0.5秒の待ち時間処理
    pwm.play(Tone(pong_f))              # PWM周波数の変更
    sleep(0.5)                          # 0.5秒の待ち時間処理
    pwm.stop()                          # PWM出力停止

print(argv[0])                          # プログラム名を表示する
if len(argv) >= 2:                      # 引数があるとき
    port_chime = int(argv[1])           # GPIOポート番号をport_chimeへ

pwm = TonalBuzzer(port)                 # PWM出力用のインスタンスを生成
chime()                                 # チャイム音
