#!/usr/bin/ruby
# -*- coding: utf-8 -*-

#ドメインの一覧とラベルをくっつけて全名前を生成する
domain_file = File.read("domains.txt") 

#label をどこぞから生成して持ってきたい
label_file = File.read(File.dirname(File.expand_path(__FILE__)) + "/labels.txt")

domain_file.each_line do |domain|
	label_file.each_line do |label|
		label.chomp!
		puts label+"."+domain
	end
end
