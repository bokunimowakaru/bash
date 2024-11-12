#!/bin/bash
###############################################################################
# LINEにメッセージを送信する
###############################################################################
#
# LINE 公式アカウントと Messaging API 用のChannel情報が必要です。
#   1. https://entry.line.biz/start/jp/ からLINE公式アカウントを取得する
#   2. https://manager.line.biz/ の設定で「Messaging APIを利用する」を実行する
#   3. Channel 情報 (Channel ID と Channel secret) を取得する
#   4. スクリプト内の変数 line_ch_id にChannel IDを記入する
#   5. スクリプト内の変数 line_ch_pw にChannel secretを記入する
#
#                      Copyright (c) 2024 Wataru KUNINO (https://bokunimo.net/)
###############################################################################
# 注意事項
# ・メッセージ送信回数の無料枠は200回/月です。超過分は有料となります。
# ・15分間だけ有効なステートレスチャネルアクセストークンを使用しています。
# 　本スクリプトでは、実行の度にTokenを取得するので問題ありません。
# 　関数line_notifyを複数回、呼び出すような場合は、15分以内にget_line_tokenで
# 　Tokenを再取得してください。(このスクリプトを改変する場合)
###############################################################################

# Messaging API用 Channel情報
line_ch_id="0000000000"                         # LINEで取得した Channel ID
line_ch_pw="00000000000000000000000000000000"   # LINEで取得した Channel secret
url_s="https://api.line.me/"                    # LINE Messaging API のURL

# LINE Messaging API用の Token の取得部
get_line_token(){
    res=`curl -s -m3 -XPOST \
        -H 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode 'grant_type=client_credentials' \
        --data-urlencode 'client_id='${line_ch_id} \
        --data-urlencode 'client_secret='${line_ch_pw}\
         ${url_s}oauth2/v3/token`               # LINEからTokenを取得する
    echo $res|tr "," "\n"|grep "access_token"|tr ":" " "|awk '{print $2}'|tr -d '"'
}

# LINE送信用の関数line_notify()定義部
line_notify() {                                 # メッセージ送信用の関数
    time=`date "+%Y/%m/%d %R"`                  # 現在の日時を取得する
    line_token="${1}"                           # LINE Token を代入
    message="${2} (${time})"                    # 引き数と日時を連結する
    # echo ${line_token}    ## デバッグ用 ##
    json='{"messages":[{"type":"text","text":"'${message}'"}]}'
    # echo ${json}          ## デバッグ用 ##
    res=`curl -s -m3 -XPOST \
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer '${line_token} \
        -d "${json}" \
        ${url_s}v2/bot/message/broadcast`       # LINEにメッセージを送信する
    if [[ ${res} ]]; then                       # 応答があった場合
        if [[ ${res}="{}" ]]; then              # メッセージが無かった場合
            echo ${message}" -> OK "            # 送信メッセージとOKを表示する
        else                                    # メッセージが存在した場合
            echo ${message}" -> "${res}         # 送信メッセージと応答を表示する
        fi
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
###############################################################################
