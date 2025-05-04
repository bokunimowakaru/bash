#!/bin/bash
###############################################################################
# ファイルの拡張子を変更します
# 
#                 Copyright (c) 2016-2025 Wataru KUNINO (https://bokunimo.net/)
###############################################################################

echo "Usage: "${0}" file-ext-from file-ext-to"
echo "       "${0}" JPG jpg"
echo "       "${0}" jpeg jpg"
echo "       "${0}" mpeg mpg"

if [[ ${#} != 2 ]]; then
    echo "ERROR: needs two input parameters, but "${#} > /dev/stderr
    exit 1
fi                                      # 条件文ifの処理の終了

files=*.${1}
if [[ `echo ${files}` == "*"* ]]; then
    echo "ERROR: no target files for ext="${1} > /dev/stderr
    exit 1
fi

ext_len=${#1}
for file_from in ${files}; do
    file_len=${#file_from}
    file_to=${file_from:0:$((file_len-ext_len))}${2}
    echo "rename "${file_from}" to "${file_to}
    mv ${file_from} ${file_to}
done
