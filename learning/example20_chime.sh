#!/bin/bash
# Example 20 チャイム音

echo "Usage: "${0}                      # プログラム名と使い方を表示する
chime_app="../gpio/chime.py"            # チャイム音の駆動にchime.pyを使用する

port=4                                  # 圧電スピーカを接続するGPIO ポート番号
${chime_app} ${port}                    # 圧電スピーカからチャイム音を出力
exit
