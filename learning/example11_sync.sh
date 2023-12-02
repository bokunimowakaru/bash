#!/bin/bash
###############################################################################
# 指定したフォルダ内とUSBメモリ内のファイルを比較し、新しいファイルに更新します
# （同期をとる）。
# 
#                 Copyright (c) 2016-2023 Wataru KUNINO (https://bokunimo.net/)
###############################################################################

echo "Usage: "${0}" [directory]"
sync_from=~/bash/learning
sync_to=~/bash/sync

# 同期元のディレクトリを変数sync_fromに保持する
if [[ ${#} > 0 ]]; then
    sync_from=${1}
fi
echo "sync_from : "${sync_from}

# 同期先のディレクトリをsync_toに保持する
sync_usb=`df|grep media|grep /dev/|grep -v ootfs|tail -1|awk '{print $6}'`
if [[ ${sync_usb} != "" ]]; then
    sync_to=${sync_usb}"/sync"
fi
mkdir -p ${sync_to}
if [[ ! -e ${sync_to} ]]; then
    echo "ERROR: cannot open "${sync_to} > /dev/stderr
    exit 1
fi
echo "sync_to   : "${sync_to}

# 同期処理
rsync -vaub ${sync_from} ${sync_to}
echo "Done"
