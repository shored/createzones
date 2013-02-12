#!/usr/bin/ruby

domain_file = File.read("domains.txt") 

#label をどこぞから生成して持ってきたい
label_file = File.read("labels.txt")

domain_file.each_line do |domain|
	label_file.each_line do |label|
		label.chomp!
		puts label+"."+domain
	end
end
