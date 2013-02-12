# Create zones, keys, signed zones, and named.conf from a fixed template and a hostlist
# ルートの時の処理が美しくない

# Read files : domains.txt

require 'erb'

class Zone
	attr_accessor :ns2, :child_zones
	attr_reader :zonename, :ns, :soa, :manageaddr

#	def display
#		puts ERB.new(File.read("db.erb")).result(binding)
#		for child in @child_zones do
#			puts child.headlabel+"    IN    NS    ns."+child.headlabel+"\n"
#			puts "ns."+child.headlabel+"	IN	A	"+child.ns+"\n"
#		end
#	end

	def zonedata
		data = ERB.new(File.read("db.erb")).result(binding)
		unless @child_zones == nil
			for child in @child_zones do
				puts "child:"+child.zonename
				data += child.headlabel+"    IN    NS    ns."+child.headlabel+"\n"
				data += "ns."+child.headlabel+"	IN	A	"+child.manageaddr+"\n"
				# 署名しないゾーンはどうしようか?
				data += File.read("zones/"+child.manageaddr+"/dsset-"+child.zonename+".")
			end
		end

		if (zonename != ".")
			data += @zskdata
			data += @kskdata
		end

		return data
	end

	def initialize(nsaddr = nil, manageaddr = nil, zonename = nil)
		@zonename = zonename
		@ns = nsaddr
		@manageaddr = manageaddr

		@soa = 'ns.'+zonename

		unless File.exist?("zones/"+@manageaddr)
			Dir.mkdir("zones/"+@manageaddr)
		end

		if (zonename != ".")
			create_dnskeys
		end
	end

	def save_zonedata
		File.open("zones/"+@manageaddr+"/"+@zonename+".db", "w") do |file|
			file.puts(zonedata)
		end
		Dir.chdir("zones/"+@manageaddr)
		`/usr/sbin/dnssec-signzone -o #{@zonename} -e +120days #{@zonename}.db`
		create_named_conf
		Dir.chdir("../../")
	end

	def create_named_conf
		data = ERB.new(File.read("../../named.conf.erb")).result(binding)
		File.open("named.conf", "w") do |file|
			file.puts(data)
		end
	end

	def headlabel
		return @zonename.slice(/^[a-zA-Z0-9]*/)
	end

private
	def create_dnskeys
		@kskname = `/usr/sbin/dnssec-keygen -K zones/#{@manageaddr} -r /dev/urandom -f KSK -a RSASHA1 -b 1024 #{@zonename}.`
		@zskname = `/usr/sbin/dnssec-keygen -K zones/#{@manageaddr} -r /dev/urandom -a RSASHA1 -b 512 #{@zonename}.`
		@kskname = @kskname.chomp
		@zskname = @zskname.chomp
		@kskdata = File.read("zones/"+@manageaddr+"/"+@kskname+".key")
		@zskdata = File.read("zones/"+@manageaddr+"/"+@zskname+".key")
	end

end

class Root < Zone
	def save_zonedata
		File.open("zones/"+@manageaddr+"/"+"fakeroot.zone", "w") do |file|
			file.puts(zonedata)
		end
		Dir.chdir("zones/"+@manageaddr)
		create_named_conf
		Dir.chdir("../../")
	end

	def create_named_conf
		data = ERB.new(File.read("../../named.conf.fakeroot")).result(binding)
		File.open("named.conf", "w") do |file|
			file.puts(data)
		end
	end

	def zonedata
		data = ERB.new(File.read("db.root.erb")).result(binding)
		unless @child_zones == nil
			for child in @child_zones do
				puts "child:"+child.zonename
				data += child.headlabel+"    IN    NS    ns."+child.headlabel+"\n"
				data += "ns."+child.headlabel+"	IN	A	"+child.manageaddr+"\n"
				# 署名しないゾーンはどうしようか?
#				data += File.read("zones/"+child.manageaddr+"/dsset-"+child.zonename+".")
			end
		end

		return data
	end
end

class Tree
	def initialize
		# create output directory
		unless File.exist?("zones")
			Dir.mkdir("zones")
		end

		@zones = []
		# 設定を引っ張って
		File.open("nsconfig.txt") do |file|
			while line = file.gets
				zone_setting = line.split(nil)
				if (zone_setting[2] == ".")
					@zones << Root.new(zone_setting[0], zone_setting[1], zone_setting[2])
				else
					@zones << Zone.new(zone_setting[0], zone_setting[1], zone_setting[2])
				end
			end
		end

		search_child_zones
	end

	def save
		@zones_sorted = @zones.sort { |a1, a2|
			a2.zonename.length <=> a1.zonename.length
		}
		for zone in @zones_sorted do
			zone.save_zonedata
			puts zone.zonedata
		end
	end

private

	def search_child_zones
		for zone in @zones do
			unless (zone.zonename == '.')
					zone.child_zones = []
					for zone_searching in @zones do
						pattern = Regexp.new("^[a-zA-Z0-9\-]*\."+zone.zonename)
						if pattern =~ zone_searching.zonename
							zone.child_zones << zone_searching
							puts "zone "+zone.zonename+" has child:\n"
							puts zone_searching.zonename+"\n"
						end
					end
			else
				zone.child_zones = []
				for zone_searching in @zones do
					pattern = Regexp.new("^[a-zA-Z0-9\-]*$")
					if pattern =~ zone_searching.zonename
						zone.child_zones << zone_searching
						puts "zone "+zone.zonename+" has child:\n"
						puts zone_searching.zonename+"\n"
					end
				end
			end
		end
	end
end

tree = Tree.new
tree.save
