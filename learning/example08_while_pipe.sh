#!/bin/bash
# Example 08 Linuxのパイプ処理と繰り返しwhile文

echo "Usage: "${0}                                  # プログラム名の表示
echo "       Press [Ctrl]+[C] key to exit."         # 終了方法の表示

while true; do                                      # 永久ループ
    ./example06_temp.sh | while read data; do       # 実行結果を標準入力
        array=(`echo ${data}`)                      # データ1行分を配列に
        if [[ ${array[0]} == "Temperature" ]];then  # 温度データのとき
            time=`date "+%Y/%m/%d %T"`              # 日時を取得
            echo ${time}", "${array[2]}             # 日時と温度を表示
        fi                                          # 温度データ処理の終了
    done                                            # 次の行の処理に戻る
    sleep 5                                         # 5秒間の待ち時間処理
done                                                # 永久ループを繰り返す
