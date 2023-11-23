#!/bin/bash
# Example 05 計算機から情報処理装置へ．コンピュータの標準入力

echo "Usage: [echo names... |] "${0}    # プログラム名と使い方を表示する

echo "Please enter your names."         # 名前の入力を促すメッセージを表示
read names                              # 標準入力のデータを変数namesに代入する

for name in ${names}; do                # namesの要素を変数nameへ代入
    echo "Hello, "${name}"!"            # 文字列Helloと変数nameの内容を表示
done                                    # forループの続きを繰り返す
