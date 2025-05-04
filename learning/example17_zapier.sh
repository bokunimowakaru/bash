#!/bin/bash
###############################################################################
# Zapier(https://zapier.com/) 送信
#
#                                         Copyright (c) 2017-2025 Wataru KUNINO
###############################################################################

# ZapierのユーザIDとWebhook用のトークンを下記に記入する
user_id="xxxxxxxx" # ZapierのユーザID
zap_id="xxxxxxx"   # Webhook用のトークン

url="https://hooks.zapier.com/hooks/catch/"${user_id}"/"${zap_id}  # URL
event_name="notify"

# Zapier送信用の関数zapier_notify()定義部
zapier_notify() {                           # メッセージ送信用の関数
    time=`date "+%Y/%m/%d %R"`              # 現在の日時を取得する
    message="${1}(${time})"                 # 引き数と日時を連結する
    res=`curl -s -m3 -XPOST\
        -H "Content-Type: application/json"\
        -d "{\"${event_name}\":\"${message}\"}"\
        ${url}` # Zapier送信
    if [[ ${res} ]]; then                   # 応答があった場合
        echo ${message}" -> "${res}         # 送信メッセージと応答を表示する
    else                                    # 応答が無かった場合
        echo "ERROR"                        # ERRORを表示
    fi                                      # ifの終了
}

# 主要処理部
echo "Usage: "${0}" [message]..."           # プログラム名と使い方を表示する
if [[ ${#} == 0 ]]; then                    # 取得した引数が0個のとき
    zapier_notify "ラズパイから送信"        # 関数zapier_notifyに文字列を渡す
else                                        # 引数が1つ以上の時
    data=`echo ${@}`                        # 入力パラメータを結合して保持
    zapier_notify "${data}"                 # zapier_notifyに入力引数を渡す
fi                                          # 条件文ifの処理の終了
exit                                        # プログラムの終了
