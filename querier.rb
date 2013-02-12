#!/usr/bin/ruby
txt = File.read("namelist.txt")

hostlist = []

txt.each_line do |line|
	hostlist << line
end

loop do
	line = hostlist[(rand * hostlist.length).to_i]
       	system("dig +dnssec @127.0.0.1 #{line}")
	sleep 0.5
end
