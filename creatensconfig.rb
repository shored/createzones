#!/usr/bin/ruby
# -*- coding: utf-8 -*-

## create nsconfig.txt file
## 管理アドレスとサーバアドレスとドメインの組

#(puppet 的な管理アドレス)	(NS の動くアドレス)	ドメイン名    出力ディレクトリ名  DNSSEC有効/無効
#AAA.AAA.AAA.AAA		BBB.BBB.BBB.BBB		ドメイン名    (ディレクトリ名)   (yes/no)

# 読みファイル
# samplehosts
# domainlist.txt

## gather の吐いた hosts ファイルを読んで吐き出す
## ドメイン名リストは別途用意
## 1. hosts ファイルから vm を集める
## 右辺値の書式は決まっている
## myrid-Int-myAS-peerAS
## というわけで、
## 1.1 myrid を集める
## 1.2 自 AS のアドレスブロックを取得
## 1.3 NS に使うアドレスを決定
##     ルータと同一ノードで DNS を動かす場合は同じ(最初の)アドレスで ok 

## results は result の配列
## result[ アドレスブロック(=使用アドレス), ルータID(=管理アドレス)] 
file = open("samplehosts")
results = []
while line = file.gets
#  print line if /vm/ =~ line
  if /^[^#].*AS/ =~ line
	address_block = line.split
	address_info = line.split[1].split("-")
	if address_info[3] == nil && address_block[2] == nil
	  result = [ address_block[0], address_info[0] ]
	  results << result
	end
  end
end

## results に ドメイン名をくっつける
file_domain = open("domainlist.txt")
domains = []
while line = file_domain.gets
	domains << line.chomp
end

## ラベルの少ない方からくっつけていけば、親が居ないという事態は無い
domains.sort!{|a, b| a.length <=> b.length }
i = 0
for result in results
	printf("%s	%s	%s	%s	%s\n", result[0], result[1], domains[i], result[1], "yes")
	i += 1
end
