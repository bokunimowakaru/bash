#!/bin/bash
# Example 03 コンピュータお得意の繰り返しfor文

echo "Usage: "${0}" [name]..."          # プログラム名と使い方を表示する

if [[ ${#} == 0 ]]; then                # 取得した引数が0個のとき
    echo "Hello, world!"                # 文字列 Hello, world! を出力する
else
    echo ${@}                           # 入力パラメータを表示する
    for name in ${@}; do                # 引数を変数nameへ代入
        echo "Hello, "${name}"!"        # 文字列Helloと変数nameの内容を表示
    done                                # forループの続きを繰り返す
fi                                      # 条件文ifの処理の終了
