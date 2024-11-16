#!/bin/bash
###############################################################################
# SSHログインエラーを監視する
###############################################################################
#
# Rsyslogがインストールされていない場合(/var/log/auth.logが無い場合)：
# sudo apt install rsyslog
#
# ※【重要】パスワードについて
# wallの実行にroot権限が必要な場合があります。
# 本スクリプトではパスワードを平文(暗号化しない)で保存する点でセキュリティ上の
# リスクがあります。
# 他にも/usr/bin/wall にNOPASSWDを設定することでパスワードを不要にする方法が
# あります。この場合はwallコマンドの脆弱性による影響を受ける場合があります。
# 
# 手動実行：
#    ./example13_ssh_mon.sh
#
#                 Copyright (c) 2023-2024 Wataru KUNINO (https://bokunimo.net/)
###############################################################################

password="****************" # ユーザのパスワードを平文で記入します【危険あり】

file_log="/home/pi/ssh_mon.log"

if [[ ${1} == "std_in" ]]; then
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
                    echo ${password} | sudo -S wall "${mesg}"
                fi
            fi
        fi
    done
else
    while true; do
        nice -n 10 tail -F /var/log/auth.log|${0} "std_in"
    done
fi
