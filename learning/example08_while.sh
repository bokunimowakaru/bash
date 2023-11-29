#!/bin/bash
# Example 08 Linuxのパイプ処理と繰り返しwhile文

echo "Usage: "${0}                                  # プログラム名の表示
echo "       Press [Ctrl]+[C] key to exit."         # 終了方法の表示

while true; do                                      # 永久ループ
    data=`./example06_temp.sh | grep "Temperature"` # 温度データを取得
    array=(`echo ${data}`)                          # データ1行分を配列に
    time=`date "+%Y/%m/%d %T"`                      # 日時を取得
    echo ${time}", "${array[2]}                     # 日時と温度を表示
    sleep 5                                         # 5秒間の待ち時間処理
done                                                # 永久ループを繰り返す
