#!/bin/bash
# I2C LCD

################################################################################
# 元ソース：
# https://github.com/bokunimowakaru/raspi_lcd/blob/master/example_Pi5.sh
# https://github.com/bokunimowakaru/raspi_lcd/blob/master/example_cpu.sh
# https://github.com/bokunimowakaru/raspi_lcd/blob/master/example.sh
################################################################################

echo "Usage: "${0}" [string1] [string2]"    # プログラム名と使い方を表示する
gpio_app="pinctrl"              # GPIO制御にpinctrlを使用する for Raspberry Pi 5
LCD_IO=4                        # LCDリセット用IOポート番号を設定する

# LCD初期化処理
${gpio_app} set ${LCD_IO} op    # ポート番号portのGPIOを出力に設定
${gpio_app} set ${LCD_IO} dl    # GPIOにLレベルを出力
sleep 0.1                       # 0.1秒の待ち時間処理
${gpio_app} set ${LCD_IO} dh    # GPIOにHレベルを出力
sleep 0.1                       # 0.1秒の待ち時間処理
i2cset -y  1 0x3e 0x00 0x39  0x14  0x73 0x56 0x6c 0x38 0x0C i
sleep 0.1                       # 0.1秒の待ち時間処理

# LCD表示用データ作成
s1="Rasp. Pi"
s2="I2C LCD"
if [[ ${#} -ge 1 ]]; then
    s1=${1}
    s2=""
fi
if [[ ${#} -ge 2 ]]; then
    s2=${2}
fi
hex1=`echo -n ${s1}| iconv -f utf8 -t sjis | od -An -tx1 | sed 's/ / 0x/g'`
hex2=`echo -n ${s2}| iconv -f utf8 -t sjis | od -An -tx1 | sed 's/ / 0x/g'`

# LCDにデータ出力
i2cset -y  1 0x3e 0x00 0x80 i
i2cset -y  1 0x3e 0x40 ${hex1} 0x20 0x20 0x20 0x20 0x20 0x20 0x20 0x20 i
i2cset -y  1 0x3e 0x00 0xc0 i
i2cset -y  1 0x3e 0x40 ${hex2} 0x20 0x20 0x20 0x20 0x20 0x20 0x20 0x20 i
