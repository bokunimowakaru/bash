#!/bin/bash
# Example 02 もしもif ～ さもなければelse ～

echo "Usage: "${0}" [name]"             # プログラム名と使い方を表示する

if [[ ${#} == 0 ]]; then                # 取得した引数が0個のとき
    echo "Hello, World!"                # 文字列 Hello, World! を出力する
else                                    # そうでないとき(引数がある時)
    echo "Hello, "${1}"!"               # 文字列Helloと引数を表示する
fi                                      # 条件文ifの処理の終了
