#!/bin/bash
###############################################################################
# SSHログインエラーを監視する 【LINE通知対応版】
###############################################################################
#
# Rsyslogがインストールされていない場合(/var/log/auth.logが無い場合)：
# sudo apt install rsyslog
#
###############################################################################
# LINE 公式アカウントと Messaging API 用のChannel情報が必要です。
#   1. https://entry.line.biz/start/jp/ からLINE公式アカウントを取得する
#   2. https://manager.line.biz/ の設定で「Messaging APIを利用する」を実行する
#   3. Channel 情報 (Channel ID と Channel secret) を取得する
#   4. スクリプト内の変数 line_ch_id にChannel IDを記入する
#   5. スクリプト内の変数 line_ch_pw にChannel secretを記入する
#
###############################################################################
# 注意事項
# ・メッセージ送信回数の無料枠は200回/月です。超過分は有料となります。
# ・15分間だけ有効なステートレスチャネルアクセストークンを使用しています。
# 　本スクリプトでは、実行の度にTokenを取得するので問題ありません。
# 　関数line_notifyを複数回、呼び出すような場合は、15分以内にget_line_tokenで
# 　Tokenを再取得してください。(このスクリプトを改変する場合)
###############################################################################
#
# 手動実行：
#    ./example13_ssh_mon.sh
# 
# 手動バックグラウンド実行：
#    nohup ./example13_ssh_mon.sh &> /dev/null &
#
# 自動実行：
#    ラズベリー・パイ起動時に自動実行するには，下記を実行する
#    $ crontab␣example13_cron.txt ⏎
#    または、/etc/rc.localに下記を追加する
#    nohup /home/pi/bash/learning/example13_ssh_mon.sh &> /dev/null &
#
#                Copyright (c) 2023-2025 Wataru KUNINO (https://bokunimo.net/)
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
    line_token="${1}"                           # LINE Token を代入
    message="${2}"                              # 引き数をmessageに代入する
    # echo ${line_token}    ## デバッグ用 ##
    json='{"messages":[{"type":"text","text":"'${message}'"}]}'
    # echo ${json}          ## デバッグ用 ##
    res=`curl -s -m3 -XPOST \
        -H 'Content-Type: application/json' \
        -H 'Authorization: Bearer '${line_token} \
        -d "${json}" \
        ${url_s}v2/bot/message/broadcast`       # LINEにメッセージを送信する
    if [[ ${res} ]]; then                       # 応答があった場合
        if [[ ${res} == "{}" ]]; then           # メッセージが無かった場合
            echo ${message}" -> OK "            # 送信メッセージとOKを表示する
        else                                    # メッセージが存在した場合
            echo ${message}" -> "${res}         # 送信メッセージと応答を表示する
        fi
    else                                        # 応答が無かった場合
        echo "ERROR"                            # ERRORを表示
    fi                                          # ifの終了
}

file_log="/home/pi/ssh_mon.log"

if [[ ${1} == "std_in" ]]; then
    # token=`get_line_token`
    # line_notify "${token}" "起動しました"
    while read line; do
        data=`echo ${line}|grep -e "password" -e "Successful" -e "FAILED"`
        if [[ ${data} ]]; then
            time=`date "+%Y/%m/%d %R"`
            if [[ ${data} =~ ^20[0-9][0-9]\- ]]; then
                data=`echo ${data}|cut -d" " -f4-`
            else
                data=`echo ${data}|cut -d" " -f6-`
            fi
            echo $data
            if [[ ${data} ]]; then
                event=`echo ${data}|cut -d" " -f1`
                mesg=""
                if [[ ${event} == "Failed" || ${event} == "FAILED" ]]; then
                    mesg="不正なSSHアクセスがありました。(${time})"
                fi
                if [[ ${event} == "Successful" ]]; then
                    mesg="ルートへのアクセスがありました。(${time})"
                fi
                if [[ ${event} == "Accepted" ]]; then
                    mesg="ログインしました。(${time})"
                fi
                if [[ ${mesg} ]]; then
                    echo ${time},${data} | tee -a ${file_log}
                token=`get_line_token`              # LINE Token を取得
                line_notify "${token}" "${mesg}"    # LINE へ送信
                fi
            fi
        fi
    done
else
    while true; do
        nice -n 10 tail -F /var/log/auth.log|${0} "std_in"
    done
fi
