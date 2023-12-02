#!/bin/bash
###############################################################################
# LAN内の機器(クラスC、192.168.1.*)にPINGを打って応答の有無を確認する
###############################################################################
# maclist.txtにMACアドレスとデバイス名の対応表を保存しておくとgrepして表示する
# 例： 00:11:22:33:44:55 Raspberry Pi 5
# 
#                 Copyright (c) 2016-2023 Wataru KUNINO (https://bokunimo.net/)
###############################################################################

ip_my=`hostname -I|tr " " "\n"|grep -Eo '([0-9]*\.){3}[0-9]*'|grep -v "127.0."|head -1`
ip_c=`echo ${ip_my}|cut -d. -f1-3`
wait="0.1"
file_mac="maclist.txt"

echo "ping "${ip_c}".*"
for i in {1..254}; do
    ping -c1 -W1 ${ip_c}"."${i}|grep "time="|while read line; do
        ip=`echo ${line}|awk '{print $4}'|tr -d ':'`
        mac=`arp ${ip}|tail -1|awk '{print $3}'`
        if [[ -e ~/maclist.txt ]]; then
            echo ${ip}" "${mac}" "`grep -i ${mac} ${file_mac}|cut -f2-`
        else
            echo ${ip}" "${mac}
        fi
    done &
    sleep ${wait}
    pid=`pidof ping`
    if [[ ${pid} ]]; then
        kill $PID &> /dev/null
    fi
done
