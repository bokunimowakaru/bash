#!/bin/bash
# exapmle14 クラウド連携の基本HTTP GET

# インターネットから情報を取得する
url="https://bokunimo.net/git/bash/raw/master/status.txt"
data=`curl -L ${url}`

# 項目ごとに抽出し、それぞれの結果を配列変数に保持する
title=`echo "${data}"|grep "title"`
descr=`echo "${data}"|grep "descr"`
state=`echo "${data}"|grep "state"`
url=`echo "${data}"|grep "url"`
date=`echo "${data}"|grep "date"`

# 9文字目以降を抽出
title=${title:8}
descr=${descr:8}
state=${state:8}
url=${url:8}
date=${date:8}

# それぞれの項目の内容を表示
echo "タイトル："${title}
echo "内　　容："${descr}
echo "状　　況："${state}
echo "Ｕ Ｒ Ｌ："${url}
echo "更 新 日："${date}
echo "所 得 日："`date "+%Y/%m/%d"`
