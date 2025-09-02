# bash: Bashスクリプトによるサンプル・プログラム集
Code Examples for Bash Script Learning

Linuxやラズベリー・パイ用のBashサンプル・プログラム集です。

## ダウンロード

[ZIP形式でダウンロードする](https://github.com/bokunimowakaru/bash/zipball/master)

## サンプル・プログラム

|  No.  | プログラム            | 内容        | Rasp Pi | Ubuntu  |
|:-----:|:----------------------|:------------|:-------:|:-------:|
|   1   |example01_hello.sh     |Hello,world! |    〇   |    〇   |
|   2   |example02_if.sh        |if～else～   |    〇   |    〇   |
|   3   |example03_for.sh       |繰り返しfor  |    〇   |    〇   |
|   4   |example04_calc.sh      |四則演算     |    〇   |    〇   |
|   5   |example05_stdin.sh     |標準入力     |    〇   |    〇   |
|   6   |example06_temp.sh      |温度測定     |    〇   |  ※[^1] |
|   7   |example07_stdout.sh    |標準出力     |    〇   |  ※[^1] |
|   8-1 |example08_while.sh     |繰り返しwhile|    〇   |  ※[^2] |
|   8-2 |example08_while_pipe.sh|パイプ処理   |    〇   |  ※[^2] |
|   9   |example09_ren.sh       |拡張子変更   |    〇   |    〇   |
|  10   |example10_backup.sh    |バックアップ |    〇   |    〇   |
|  11   |example11_sync.sh      |ファイル同期 |    〇   |    〇   |
|  12   |example12_ping.sh      |PING応答確認 |    〇   |    〇   |
|  13   |example13_ssh_mon.sh   |SSHエラー監視|    〇   |    〇   |
|  14   |example14_htget.sh     |HTTP GET     |    〇   |    〇   |
|  15-1 |example15_temp.sh      |温度値を送信 |    〇   |  ※[^1] |
|  15-2 |example15_ambient.sh   |Ambientへ送信|    〇   |  ※[^1] |
|  16   |example16_line.sh      |LINEに送信   |    〇   |    〇   |
|  17-1 |example17_ifttt.sh     |IFTTTへ送信  |    〇   |    〇   |
|  17-2 |example17_zapier.sh    |Zapierへ送信 |    〇   |    〇   |
|  18   |example18_led.sh       |Lチカ BASIC  |    〇   |    ×   |
|  19   |example19_led3.sh      |カラー Lチカ |    〇   |    ×   |
|  20   |example20_chime.sh     |チャイム音   |    〇   |    ×   |
|  21-1 |example21_btn.sh       |ボタン送信機 |    〇   |    ×   |
|  21-2 |example21_line_btn.sh  |LINEに送信   |    〇   |    ×   |
|  21-3 |example21_pir.sh       |人感センサ   |    〇   |    ×   |
|  23   |example22_sht4.sh      |温湿度センサ |    〇   |    ×   |
|  23   |example23_lcd_i2c.sh   |LCDに文字表示|    〇   |    ×   |
|  24   |example24_lcd_udp.sh   |UDPモニター  |    〇   |    ×   |
|  25   |example25_jukebox.sh   |音楽ボックス |    〇   |    ×   |
|  26   |example26_udp_rx.sh    |UDP Reciever |    〇   |    〇   |
|  27   |example27_led3_http.sh |HTTPサーバLED|    〇   |    ×   |
|  28   |example28_chime_udp.sh |呼鈴システム |    〇   |    ×   |
|  29   |example29_cam_http.sh  |Piカメラ制御 |    〇   |    ×   |
|  30-1 |example30_m2m.sh       |玄関カメラ   |    〇   |    〇   |
|  30-2 |example30_m2m_mail.sh  |メール送信   |    〇   |    〇   |

[^1]: PCで使用する場合は、変数fileで指定する温度ファイルを変更する必要があります。

[^2]: example06_temp.shを※[^1]にしたがって改造すれば動作します。

### PCでCPUの温度を測定する方法/固定値を使用する方法

一例として、以下のように設定します(システムや環境によって異なります)。  

	/sys/class/hwmon/hwmon1/temp1_input

または、固定値（一例として「25000」）を書いたファイルを保存し、そのパスを
変数fileに指定すれば動作します。

--------------------------------------------------------------------------------
## ライセンス(全般)

* ライセンスについては各ソースリストならびに各フォルダ内のファイルに記載の通りです。  
* 使用・変更・配布は可能ですが、権利表示を残してください。  
* 提供情報や配布ソフトによって、被害が生じた場合であっても、当方は、一切、補償いたしません。  
* ライセンスが明記されていないファイルについても、同様です。  

	Copyright (c) 2019-2023 Wataru KUNINO <https://bokunimo.net/>  

----------------------------------------------------------------

## GitHub Pages (This Document)
* [https://git.bokunimo.com/bash/](https://git.bokunimo.com/bash/)  

----------------------------------------------------------------

# git.bokunimo.com GitHub Pages site
[http://git.bokunimo.com/](http://git.bokunimo.com/)  

----------------------------------------------------------------
