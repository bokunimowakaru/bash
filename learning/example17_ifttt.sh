#!/bin/bash
###############################################################################
# IFTTT 送信
#
#                                         Copyright (c) 2017-2025 Wataru KUNINO
###############################################################################

# IFTTTのKeyを(https://ifttt.com/maker_webhooks)から取得し、変数keyへ代入する
key="xx_xxxx_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # IFTTTのKey(鍵)
url="https://maker.ifttt.com/trigger"             # IFTTTのURL(変更不要)
event_name="notify"

# IFTTT送信用の関数ifttt_notify()定義部
ifttt_notify() {                            # メッセージ送信用の関数
    time=`date "+%Y/%m/%d %R"`              # 現在の日時を取得する
    message="${1}(${time})"                 # 引き数と日時を連結する
    res=`curl -s -m3 -XPOST\
        -H "Content-Type: application/json"\
        -d "{\"value1\":\"${message}\"}"\
        ${url}/${event_name}/with/key/${key}` # IFTTT送信
    if [[ ${res} ]]; then                   # 応答があった場合
        echo ${message}" -> "${res}         # 送信メッセージと応答を表示する
    else                                    # 応答が無かった場合
        echo "ERROR"                        # ERRORを表示
    fi                                      # ifの終了
}

# 主要処理部
echo "Usage: "${0}" [message]..."           # プログラム名と使い方を表示する
if [[ ${#} == 0 ]]; then                    # 取得した引数が0個のとき
    ifttt_notify "ラズパイから送信"         # 関数line_notifyに文字列を渡す
else                                        # 引数が1つ以上の時
    data=`echo ${@}`                        # 入力パラメータを結合して保持
    ifttt_notify "${data}"                  # line_notifyに入力引数を渡す
fi                                          # 条件文ifの処理の終了
exit                                        # プログラムの終了
