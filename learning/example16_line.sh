#!/bin/bash
###############################################################################
# LINEにメッセージを送信する
###############################################################################
#
# LINE 公式アカウントと Messaging API 用のChannel情報が必要です。
#    1. https://manager.line.biz/ へアクセス
#
#                      Copyright (c) 2024 Wataru KUNINO (https://bokunimo.net/)
###############################################################################

# Messaging API用 Channel情報
line_ch_id="0000000000"                         # LINEで取得した Channel ID
line_ch_pw="00000000000000000000000000000000"   # LINEで取得した Channel secret
url_s="https://api.line.me/"                    # LINE Messaging API のURL

# LINE Messaging API用の Token の取得部
get_line_token(){
    res=`curl -s -m3 -XPOST\
        -H 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode 'grant_type=client_credentials' \
        --data-urlencode 'client_id='${line_ch_id} \
        --data-urlencode 'client_secret='${line_ch_pw}\
         ${url_s}oauth2/v3/token`               # LINEからTokenを取得する
    echo $res|tr "," "\n"|grep "access_token"|tr ":" " " |awk '{print $2}'|tr -d '"'
}

# LINE送信用の関数line_notify()定義部
line_notify() {                                 # メッセージ送信用の関数
    time=`date "+%Y/%m/%d %R"`                  # 現在の日時を取得する
    line_token="${1}"                           # LINE Token を代入
    message="${2}(${time})"                     # 引き数と日時を連結する
    echo ${line_token}
    json='{"messages":[{"type":"text","text":"'${message}'"}]}'
    echo ${json}
    res=`curl -s -m3 -XPOST\
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer '${line_token} \
        -d ${json} \
        ${url_s}v2/bot/message/broadcast`       # LINEにメッセージを送信する
    if [[ ${res} ]]; then                       # 応答があった場合
        echo ${message}" -> OK "${res}          # 送信メッセージと応答を表示する
    else                                        # 応答が無かった場合
        echo "ERROR"                            # ERRORを表示
    fi                                          # ifの終了
}

# 主要処理部
echo "Usage: "${0}" [message]..."               # プログラム名と使い方を表示する
token=`get_line_token`                          # LINE Token を取得

if [[ ${#} == 0 ]]; then                        # 取得した引数が0個のとき
    line_notify "${token}" "ラズパイから送信"   # 関数line_notifyに文字列を渡す
else                                            # 引数が1つ以上の時
    data=`echo ${@}`                            # 入力パラメータを結合して保持
    line_notify "${token}" "${data}"            # line_notifyに入力引数を渡す
fi                                              # 条件文ifの処理の終了
exit                                            # プログラムの終了

###############################################################################
# 参考文献：下記のcurl文の一部を引用しました
# LINE DevelopersLINE Developers, Messaging APIリファレンス
# https://developers.line.biz/ja/reference/messaging-api/
