#!/bin/bash
###############################################################################
# LINEにメッセージを送信する
###############################################################################
#
# LINE アカウントと LINE Notify 用のトークンが必要です。
#    1. https://notify-bot.line.me/ へアクセス
#    2. 右上のアカウントメニューから「マイページ」を選択
#    3. アクセストークンの発行で「トークンを発行する」を選択
#    4. トークン名「raspi」（任意）を入力
#    5. 送信先のトークルームを選択する(「1:1でLINE Notifyから通知を受け取る」)
#    6. [発行する]ボタンでトークンが発行される
#    7. [コピー]ボタンでクリップボードへコピー
#    8. 下記のline_tokenに貼り付け
#
#                      Copyright (c) 2023 Wataru KUNINO (https://bokunimo.net/)
###############################################################################

line_token="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # LINEで取得したTOKEN
url_s="https://notify-api.line.me/api/notify"            # LINE Notify のURL
    # 'Authorization':'Bearer ' + line_token
    # 'Content-Type':'application/x-www-form-urlencoded; charset=UTF-8'

# LINE送信用の関数line_notify()定義部
line_notify() {                             # メッセージ送信用の関数
    time=`date "+%Y/%m/%d %R"`              # 現在の日時を取得する
    message="${1}(${time})"                 # 引き数と日時を連結する
    res=`curl -s -m3 -XPOST\
         -H "Authorization:Bearer ${line_token}"\
         -d "message=${1}(${time})"\
         ${url_s}`                          # LINEにメッセージを送信する
    if [[ ${res} ]]; then                   # 応答があった場合
        echo ${message}" -> "${res}         # 送信メッセージと応答を表示する
    else                                    # 応答が無かった場合
        echo "ERROR"                        # ERRORを表示
    fi                                      # ifの終了
}

# 主要処理部
echo "Usage: "${0}" [message]..."           # プログラム名と使い方を表示する
if [[ ${#} == 0 ]]; then                    # 取得した引数が0個のとき
    line_notify "ラズパイから送信"          # 関数line_notifyに文字列を渡す
else                                        # 引数が1つ以上の時
    data=`echo ${@}`                        # 入力パラメータを結合して保持
    line_notify "${data}"                   # line_notifyに入力引数を渡す
fi                                          # 条件文ifの処理の終了
exit                                        # プログラムの終了
