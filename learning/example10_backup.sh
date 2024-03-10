#!/bin/bash
###############################################################################
# 入力ファイルを圧縮して保存します。
###############################################################################
# デスクトップ環境かつUSBメモリがある時はUSBメモリに、
# LITE版やUSBメモリが無い場合は、
# ~/bash/backupに保存します。
#
#   crontabに以下を追加すれば、毎日0:10に、自動実行することが出来ます。
#   # m h  dom mon dow   command
#   10 0 * * * ~/bash/learning/example10_backup.sh ~/bash/learning/*
# 
#                   Copyright (c) 2016-2023 Wataru KUNINO https://bokunimo.net/
###############################################################################

echo "Usage: "${0}" [filename]..."
backup_from=~/bash/learning/*
backup_to=~/bash/backup

# バックアップ元のファイルを変数backup_fromに保持する
if [[ ${#} > 0 ]]; then
    backup_from=${@}
fi
echo "backup_from : "${backup_from}

# バックアップ先のディレクトリをbackup_toに保持する
backup_usb=`df|grep media|grep /dev/|grep -v /.ootfs$|grep -v /.oot$|tail -1|awk '{print $6}'`
if [[ ${backup_usb} != "" ]]; then
    backup_to=${backup_usb}"/backup"
fi
mkdir -p ${backup_to}
backup_to=${backup_to}"/"`date "+%Y%m%d"`".zip"
if [[ -e ${backup_to} ]]; then
    rm ${backup_to}
    echo "removed "${backup_to}
fi
echo "backup_to   : "${backup_to}

# バックアップ処理
zip ${backup_to} ${backup_from}
echo "Done"
