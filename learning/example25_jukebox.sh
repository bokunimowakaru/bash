#!/bin/bash
# Internet music_box with LCD

################################################################################
# 元ソース：
# https://github.com/bokunimowakaru/audio/blob/master/music_box/pi/music_box.sh
# https://github.com/bokunimowakaru/raspi_lcd/blob/master/example_Pi5.sh
# https://github.com/bokunimowakaru/raspi_lcd/blob/master/raspi_i2c.c
################################################################################

# 解説：
#   実行すると楽曲ファイルを再生します。
#   GPIO 26に接続したボタンを押すと楽曲を切り替えます。
#
# ffmpegのインストール：
#   $ sudo apt install ffmpeg ⏎

# GPIO設定部
LCD_IO=4                        # LCDリセット用IOポート番号を設定する
BTN_IO=26                       # タクトスイッチのGPIO ポート番号

# 楽曲ファイルの登録
plist=(
    "../media/music/Thirsty.mp3"
    "../media/music/Short-Cut.mp3"
    "../media/music/Wonderful.mp3"
)
plist_n=${#plist[@]}

# 音楽再生用の関数を定義
music_box (){
    echo `date` "music_box Num =" $1
    if [ $1 -ge 1 ] && [ $1 -le $plist_n ]; then
        name=(${plist[$(($1 - 1))]})
        echo `date` "Internet music_box =" ${name}
        kill `pidof ffplay` &> /dev/null
        ffplay -nodisp -autoexit ${name} 2>&1 | ${0} lcd_out &
    else
        echo `date` "ERROR music_box Num" $1
    fi
}

# LCD表示用の関数を定義
lcd (){
    s=${@}                                    # 全パラメータを変数sに代入
    s1=${s:0:8}                               # 受信データの先頭8バイト
    s2=${s:8:10}                              # 9バイト目以降10バイトを抽出
    s2=${s2:0:8}                              # 8文字までに制限
    echo `date` "lcd_out =" ${s1} "/" ${s2}   # LCD出力内容を表示
    hex1=`echo -n $s1|iconv -f utf8 -t sjis|od -An -tx1|sed 's/ / 0x/g'`
    hex2=`echo -n $s2|iconv -f utf8 -t sjis|od -An -tx1|sed 's/ / 0x/g'`
    i2cset -y 1 0x3e 0x00 0x80 i
    i2cset -y 1 0x3e 0x40 ${hex1} 32 32 32 32 32 32 32 32 i
    i2cset -y 1 0x3e 0x00 0xc0 i
    i2cset -y 1 0x3e 0x40 ${hex2} 32 32 32 32 32 32 32 32 i
}

# メタデータ（TITLE）の表示実行部
if [[ ${1} == "lcd_out" ]]; then
    echo `date` "Started Subprocess lcd_out"
    while read s; do
        s=`echo ${s}|grep "TITLE *:"|cut -d" " -f3-`
        if [[ -n ${s} ]]; then
            echo `date` "Metadata (TITLE) =" ${s}
            lcd ${s}
        fi
    done
    exit
fi

# メイン処理部 #################################################################
echo "Usage:" ${0}              # プログラム名と使い方を表示する
gpio_app="pinctrl"              # GPIO制御にpinctrlを使用する for Raspberry Pi 5
# gpio_app="raspi-gpio"         # GPIO制御にraspi-gpioを使用する

# ボタン・LCD初期化処理
${gpio_app} set ${BTN_IO} ip    # ポート番号BTN_IOのGPIOを入力に設定
${gpio_app} set ${BTN_IO} pu    # ポート番号BTN_IOをプルアップ
${gpio_app} set ${LCD_IO} op    # ポート番号LCD_IOのGPIOを出力に設定
${gpio_app} set ${LCD_IO} dl    # GPIOにLレベルを出力
sleep 0.1                       # 0.1秒の待ち時間処理
${gpio_app} set ${LCD_IO} dh    # GPIOにHレベルを出力
sleep 0.1                       # 0.1秒の待ち時間処理
i2cset -y  1 0x3e 0x00 0x39  0x14  0x73 0x56 0x6c 0x38 0x0C i
sleep 0.1                       # 0.1秒の待ち時間処理
lcd "Jukebox ffPlayer"          # LCDにタイトルを表示

num=0                           # 楽曲番号
while true; do                  # 永久ループ
    pidof ffplay > /dev/null                # ffplayが動作しているかどうかを確認
    if [ $? -ne 0 ]; then                   # 動作していなかったとき
        echo `date` "PLAY music_box"        # PLAY music_boxを表示
        num=$(( num + 1 ))                  # 楽曲番号に1を加算
        if [[ ${num} -gt ${plist_n} ]]; then # 楽曲数を超えていた時
            num=1                           # 楽曲番号を1に設定する
        fi
        lcd ${plist[$(( num - 1 ))]##*/}    # plistに登録した楽曲名を表示
        music_box ${num}                    # 関数 music_boxを呼び出し
        trap "kill `pidof ffplay` &> /dev/null" EXIT # 終了時にffplayを終了する
        sleep 1                             # 0.1秒の待ち時間処理
    fi
    btn=`${gpio_app} get ${BTN_IO}`         # ボタン状態を取得
    if [[ ${btn:15:2} == "lo" ]]; then      # 入力値がLレベルの時
        btn=1                               # 変数btnに1を代入
    elif [[ ${btn:15:2} == "hi" ]]; then    # 入力値がHレベルの時
        btn=0                               # 変数btnに0を代入
    else                                    # その他の場合(raspi-gpioなど)
        btn=`echo ${btn}|tr " " "\n"|grep "level="` # ボタンレベル値を取得
        btn=${btn:6:1}                      # レベル値を抽出
        if [[ -n ${btn} ]]; then            # レベル値が得られたとき
            btn=$(( ! ${btn} ))             # 変数btnの論理を反転
        else                                # 抽出できなかったとき
            btn=0                           # 変数btnに0を代入
        fi
    fi
    if [[ btn -eq 1 ]]; then                # ボタンが押された時
        echo `date` "USER Button Pressed"   # 表示
        kill `pidof ffplay` &> /dev/null    # ffplayを終了
        sleep 1                             # 終了待ち・チャタリング防止
    fi
done                                        # 永久ループを繰り返す
