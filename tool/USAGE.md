# database_import.rb の使い方

TwinCal は KdB の科目情報をスクレイピングしているわけではなく、
KdB の全データを事前にデータベース化している。

database_import.rb は、KdB の出力する CSV ファイルを SQlite3 のテーブルに変換するスクリプト。

## 使い方

### KdB から 科目情報のCSV をダウンロードする

1. [KdB](https://kdb.tsukuba.ac.jp/) にアクセス
2. 年度だけ指定して検索して、その年度の全データを表示する。
3. 科目一覧ﾌｧｲﾙ形式 のドロップダウンメニューから CSV形式 を選択する。
4. 科目一覧ダウンロード ボタンを押すと、kdb_20140402080858.csv というような名前 CSV ファイルをダウンロードできる。
5. KdB が出力するCSV はフォーマットが壊れていて、csv gem ではパースできない。
   LibreOffice で開き、別名で保存すると、正しいフォーマットのCSVに変換できる。
   ここでは kdb_20140402080858_2.csv という名前で別名で保存する。

### CSV から DB のテーブルに変換する

```sh
$ cd twincal2/tool
$ rm kamoku.db
$ ruby database_import.rb kdb_20140402080858_2.csv
正常に処理が終了しました。(16892件)
$ cp kamoku.db ../kamoku.db
```
