#!/usr/bin/python3
## 注：Shebangを#!/usr/bin/env python3にするとpidofがスクリプトと認識しない

###############################################################################
# GPIO 制御用 HTTPサーバ [GPIO Zero 版]
#
# 参考文献：
# https://gpiozero.readthedocs.io/
#
#                   Copyright (c) 2023-2024 Wataru KUNINO https://bokunimo.net/
###############################################################################

from gpiozero import Button
from gpiozero import LED
from wsgiref.simple_server import make_server
from time import sleep                          # スリープ実行モジュールの取得
from sys import argv                            # 本プログラムの引数argvを取得
import threading                                # スレッド用ライブラリの取得

port = 4
leds_dict = dict()
btns_dict = dict()

print(argv[0])                                  # プログラム名を表示する

def wsgi_app(environ, start_response):          # HTTPアクセス受信時の処理
    global port                                 # 変数portを関数外から取得
    if environ.get('PATH_INFO')!='/' or environ.get('REQUEST_METHOD')!='GET':
        start_response('404 Not Found',[])      # 不正リクエストへの応答文
        return ['404 Not Found'.encode()]       # 応答メッセージ(404)を返却
    queries = environ.get('QUERY_STRING')       # クエリを取得(全文)
    if not queries.isprintable() or len(queries) > 256 : # クエリの条件確認
        start_response('404 Not Found',[])      # 404エラー応答を設定
        return ['404 Not Found'.encode()]       # 応答メッセージ(404)を返却
    res = 'GPIO '+str(port)+': NA'              # 応答文を作成
    queries = queries.lower().split('&')        # クエリを項目ごとに分解
    print('\n---- REQUESTED ---- ',end='')
    print('Queries:',queries)                   # クエリ確認用
    for query in queries:
        if query.startswith('port='):
            try:
                port=int(query[5:])
                res = 'GPIO '+str(port)+': NA'  # 応答文を作成
            except:
                print('ERROR: query port')
        if query.startswith('out'):
            try:
                b=int(query[4:])
            except:
                b=-1
                print('ERROR: query value')
            led = leds_dict.get(port)
            if led is None:
                try:
                    leds_dict[port] = LED(port)
                    led = leds_dict.get(port)
                except:
                    print('ERROR: GPIO LED, get port')
            if (led is not None) and (b >= 0):
                led.value = b
                res = 'GPIO '+str(port)+': level=' + str(b)
        if query.startswith('in'):
            btn = btns_dict.get(port)
            if btn is None:
                btn = leds_dict.get(port)
            if btn is None:
                try:
                    btns_dict[port] = Button(port, pull_up=True)
                    btn = btns_dict.get(port)
                except:
                    print('ERROR: GPIO Button, get port')
            if btn is not None:
                res = 'GPIO '+str(port)+': level=' + str(btn.value)
        if query == 'close':
            led = leds_dict.get(port)
            if led is not None:
                led.close()
                del leds_dict[port]
            else:
                btn = btns_dict.get(port)
                if btn is not None:
                    btn.close()
                    del btns_dict[port]
    print(res)                                  # 応答メッセージを表示
    res = (res + '\r\n').encode('utf-8')        # 改行コード付与とバイト列へ変換
    start_response('200 OK', [('Content-type', 'text/plain; charset=utf-8')])
    return [res]                                # 応答メッセージを返却

try:
    httpd = make_server('', 8080, wsgi_app)     # ポート8080でHTTPサーバ実体化
    print("HTTP port 8080")                     # 起動ポート番号の表示
    print("e.g. http://127.0.0.1:8080/?port=4&out=1") # 一例を表示
    print("     http://127.0.0.1:8080/?port=4&out=0") # デジタル出力
    print("     http://127.0.0.1:8080/?port=4&in")    # デジタル入力
    print("     http://127.0.0.1:8080/?port=4&close") # ポートを閉じる
except PermissionError:                         # 例外処理発生時(アクセス拒否)
    exit()                                      # プログラムの終了
try:
    httpd.serve_forever()                       # HTTPサーバを起動
except KeyboardInterrupt:                       # キー割り込み発生時
    print('\nKeyboardInterrupt')                # キーボード割り込み表示
    exit()                                      # プログラムの終了

'''
実行例：
pi@raspberrypi:~/bash/gpio $ ./gpio_srv.py
./gpio_srv.py
HTTP port 8080
e.g. http://127.0.0.1:8080/?port=4&out=1
     http://127.0.0.1:8080/?port=4&out=0
     http://127.0.0.1:8080/?port=4&in
     http://127.0.0.1:8080/?port=4&close

---- REQUESTED ---- Queries: ['port=4', 'out=1']
GPIO 4: level=1
192.168.0.6 - - [09/Dec/2023 03:11:36] "GET /?port=4&out=1 HTTP/1.1" 200 9

---- REQUESTED ---- Queries: ['port=4', 'out=0']
GPIO 4: level=0
192.168.0.6 - - [09/Dec/2023 03:11:48] "GET /?port=4&out=0 HTTP/1.1" 200 9

---- REQUESTED ---- Queries: ['port=4', 'in']
GPIO 4: level=0
192.168.0.6 - - [09/Dec/2023 03:11:55] "GET /?port=4&in HTTP/1.1" 200 9

---- REQUESTED ---- Queries: ['port=4', 'close']
GPIO 4: NA
192.168.0.6 - - [09/Dec/2023 03:12:01] "GET /?port=4&close HTTP/1.1" 200 10
'''
