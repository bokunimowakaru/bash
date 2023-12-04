#!/usr/bin/env python3
###############################################################################
# Example 13 チャイム
###############################################################################
#
# https://github.com/bokunimowakaru/iot/blob/master/learning/example13_chime.py
#
#                   Copyright (c) 2019-2023 Wataru KUNINO https://bokunimo.net/
###############################################################################

port_chime = 4                                  # チャイム用 GPIO ポート番号
ping_f = 554                                    # チャイム音の周波数1
pong_f = 440                                    # チャイム音の周波数2

from RPi import GPIO                            # GPIOモジュールの取得
from time import sleep                          # スリープ実行モジュールの取得
from sys import argv                            # 本プログラムの引数argvを取得
# import threading                              # スレッド用ライブラリの取得

def chime():                                    # チャイム（スレッド用）
    # mutex.acquire()                           # mutex状態に設定(排他処理開始)
    pwm.ChangeFrequency(ping_f)                 # PWM周波数の変更
    pwm.start(50)                               # PWM出力を開始。デューティ50％
    sleep(0.5)                                  # 0.5秒の待ち時間処理
    pwm.ChangeFrequency(pong_f)                 # PWM周波数の変更
    sleep(0.5)                                  # 0.5秒の待ち時間処理
    pwm.stop()                                  # PWM出力停止
    # mutex.release()                           # mutex状態の開放(排他処理終了)

print(argv[0])                                  # プログラム名を表示する
if len(argv) >= 2:                              # 引数があるとき
    port_chime = int(argv[1])                   # GPIOポート番号をport_chimeへ
GPIO.setmode(GPIO.BCM)                          # ポート番号の指定方法の設定
GPIO.setup(port_chime, GPIO.OUT)                # ポート番号port_chimeを出力に

pwm = GPIO.PWM(port_chime, ping_f)              # PWM出力用のインスタンスを生成
chime()                                         # チャイム音
sleep(0.1)                                      # 0.1秒間の待ち時間処理
GPIO.cleanup(port_chime)                        # GPIOを未使用状態に戻す

'''
# mutex = threading.Lock()                      # 排他処理用のオブジェクト生成
prev = 1                                        # 前回のボタン状態を保持する

try:
    while True:                                 # 繰り返し処理
        if prev == b:                           # 前回の値と一致
            sleep(0.1)                          # 0.1秒間の待ち時間処理
            continue                            # whileに戻る
        if b == 0:                              # ボタンが押された時
            thread = threading.Thread(target=chime) # 関数chimeをスレッド化
            thread.start()                      # スレッドchimeの起動
        sleep(0.1)                              # 0.1秒間の待ち時間処理
        prev = b                                # 変数prevにボタン状態を保存
except KeyboardInterrupt:                       # キー割り込み発生時
    print('\nKeyboardInterrupt')                # キーボード割り込み表示
    GPIO.cleanup(port_chime)                    # GPIOを未使用状態に戻す
    exit()                                      # プログラムの終了
'''
