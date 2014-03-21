#!/usr/bin/ruby

# Create all domains from namelist.
# ex: (www.sub.example.com -> .com .example.com sub.example.com )

labels = []
domains = Hash.new

STDIN.each do |line|
	labels = line.chomp.split('.')
	current_name = ""
	i = labels.size - 1
	while  i > 0
		current_name = labels[i] + "." + current_name
		domains[current_name] = 1
		i -= 1
	end
end

domains.each {|key, data|
	print key + "\n"
}
