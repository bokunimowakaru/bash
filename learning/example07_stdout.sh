#!/bin/bash
# Example 07 Linuxの標準出力とファイル保存

echo "Usage: "${0}" [output]"           # プログラム名と使い方を表示する
echo "       "${0}" /dev/stdout"        # 標準出力(LXTerminal)に表示する
echo "       "${0}" output.csv"         # ファイルに保存する

filename="/dev/stdout"                  # ファイル名の標準出力

if [[ ${#} > 0 ]]; then                 # 取得した引数が1個以上のとき
    filename="${1}"                     # ファイル名を変数filenameに保持
fi                                      # 条件文ifの終了

temp=$((`cat /sys/class/thermal/thermal_zone0/temp` / 1000)) # 温度を取得
time=`date "+%Y/%m/%d %R"`              # 日時を取得

echo ${time}", "${temp} >> ${filename}  # 日時と温度を出力する
  #  |~~~~~~    |~~~~~~    |~~~~~~~~~~
  #  +--日時    +--温度    +--出力先

# ファイル内容表示
if [[ ${#} > 0 ]]; then                 # 取得した引数が1個以上のとき
    echo ${filename}":"                 # ファイル名を表示
    cat ${filename}                     # ファイルの内容を表示
fi                                      # 条件文ifの処理の終了
