#!/bin/bash
###############################################################################
# SSHログインエラーを監視する
###############################################################################
#
# Rsyslogがインストールされていない場合(/var/log/auth.logが無い場合)：
# sudo apt install rsyslog
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
# 手動実行：
#    ./example13_ssh_mon.sh
# 
# 手動バックグラウンド実行：
#    nohup ./example13_ssh_mon.sh &> /dev/null &
#
# 自動実行：
#    crontabまたは/etc/rc.localに下記を追加する
#    nohup /home/pi/bash/learning/example13_ssh_mon.sh &> /dev/null &
#
#                      Copyright (c) 2023 Wataru KUNINO (https://bokunimo.net/)
###############################################################################

file_log="/home/pi/ssh_mon.log"
line_token="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # LINEで取得したTOKEN
url_s="https://notify-api.line.me/api/notify"            # LINE Notify のURL
    # 'Authorization':'Bearer ' + line_token
    # 'Content-Type':'application/x-www-form-urlencoded; charset=UTF-8'

line_notify () {
    wall ${1}
    curl -X POST\
         -H "Authorization:Bearer ${line_token}"\
         -d "message=${1}"\
         ${url_s}
}

if [[ ${1} == "std_in" ]]; then
    # line_notify "起動しました"
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
                    line_notify "${mesg}"
                fi
            fi
        fi
    done
else
    while true; do
        nice -n 10 tail -F /var/log/auth.log|${0} "std_in"
    done
fi
