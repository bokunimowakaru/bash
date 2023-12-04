#!/bin/bash
# Example 20 チャイム

echo "Usage: "${0}                      # プログラム名と使い方を表示する
chime_app="../gpio/chime.py"            # チャイム音の駆動にchime.pyを使用する

port=4                                  # GPIO ポート番号
${chime_app} ${port}                    # ポート番号portのGPIOを出力に設定
exit
