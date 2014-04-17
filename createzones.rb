# -*- coding: utf-8 -*-
# Create zones, keys, signed zones, and named.conf from a fixed template and a hostlist
# ルートの時の処理が美しくない
# 最後に名前を各ゾーンに入れ込む処理が必要

# Read files : domains.txt

require 'erb'
require 'optparse'
require 'fileutils'


class Zone
	attr_accessor :ns2, :child_zones
	attr_reader :zonename, :ns, :soa, :manageaddr, :zonedir, :isdnssec

#	def display
#		puts ERB.new(File.read(File.dirname(File.expand_path(__FILE__)) + "db.erb")).result(binding)
#		for child in @child_zones do
#			puts child.headlabel+"    IN    NS    ns."+child.headlabel+"\n"
#			puts "ns."+child.headlabel+"	IN	A	"+child.ns+"\n"
#		end
#	end

	def issigned
		return @issigned
	end

	def issigned=(value)
		@issigned = value
	end

	def zonedata
		data = ERB.new(File.read(File.dirname(File.expand_path(__FILE__)) + "/db.erb"), nil, '-').result(binding)
		unless @child_zones == nil
			for child in @child_zones do
				puts "child:"+child.zonename
				data += child.headlabel+"    IN    NS    ns."+child.headlabel+"\n"
				data += "ns."+child.headlabel+"	IN	A	"+child.manageaddr+"\n"
				# 署名しないゾーンはどうしようか?
                                if (child.issigned != "")
                                  data += File.read(@outdir+child.zonedir+"/tmp/namedb/dsset-"+child.zonename+".")
                                end
			end
		end

		if (zonename != ".")
			data += @zskdata
			data += @kskdata
		end

		return data
	end

	def initialize(nsaddr = nil, manageaddr = nil, zonename = nil, zonedir = nil, isdnssec = "yes", outdir = "zones/")
		@zonename = zonename
		@ns = nsaddr
		@manageaddr = manageaddr
                if (zonedir == nil)
                  zonedir = @zonename
                end
		@zonedir = zonedir +"/"
                @outdir = outdir

		@soa = 'ns.'+zonename
          	@issigned = ''
          	if (isdnssec == "yes")
                  @issigned = '.signed'
                end

		unless File.exist?(@outdir+@zonedir+"/tmp/namedb/")
			FileUtils.mkdir_p(@outdir+@zonedir+"/tmp/namedb/")
		end

		create_dnskeys
	end

	def save_zonedata
		File.open(@outdir+@zonedir+"/tmp/namedb/"+@zonename+".db", "w") do |file|
			file.puts(zonedata)
		end
                if (@issigned != "")
                  `#{$dnssec_signzone_exec} -o #{@zonename} -e +120days -K #{@outdir}/#{@zonedir}/tmp/namedb/ #{@outdir}#{@zonedir}/tmp/namedb/#{@zonename}.db`
                  `mv dsset-#{@zonename}. #{@outdir}/#{@zonedir}/tmp/namedb/`
                end
		create_named_conf
	end

	def create_named_conf
		data = ERB.new(File.read(File.dirname(File.expand_path(__FILE__)) + "/named.conf.erb")).result(binding)
		File.open(@outdir+@zonedir+"/tmp/namedb/named.conf", "w") do |file|
			file.puts(data)
		end
	end

	def headlabel
		return @zonename.slice(/^[a-zA-Z0-9\-]*/)
	end

private
	def create_dnskeys
		if ( $no_create_dnskey != true)
              	  @kskname = `#{$dnssec_keygen_exec} -K #{@outdir}#{@zonedir}/tmp/namedb/ -r /dev/urandom -f KSK -a RSASHA1 -b 1024 #{@zonename}.`
              	  @zskname = `#{$dnssec_keygen_exec} -K #{@outdir}#{@zonedir}/tmp/namedb/ -r /dev/urandom -a RSASHA1 -b 512 #{@zonename}.`
		end

		@kskname = @kskname.chomp
		@zskname = @zskname.chomp
		@kskdata = File.read(@outdir+@zonedir+"/tmp/namedb/"+@kskname+".key")
		@zskdata = File.read(@outdir+@zonedir+"/tmp/namedb/"+@zskname+".key")
	end

end

class Root < Zone
	def save_zonedata
		File.open(@outdir+@zonedir+"/tmp/namedb/"+"fakeroot.zone", "w") do |file|
			file.puts(zonedata)
		end
		create_named_conf
	end

	def create_named_conf
		data = ERB.new(File.read(File.dirname(File.expand_path(__FILE__)) +"/named.conf.fakeroot")).result(binding)
		File.open(@outdir+@zonedir+"/tmp/namedb/named.conf", "w") do |file|
			file.puts(data)
		end
	end

	def zonedata
		data = ERB.new(File.read(File.dirname(File.expand_path(__FILE__)) + "/db.root.erb")).result(binding)
		unless @child_zones == nil
			for child in @child_zones do
				puts "child:"+child.zonename
				data += child.headlabel+"    IN    NS    ns."+child.headlabel+"\n"
				data += "ns."+child.headlabel+"	IN	A	"+child.manageaddr+"\n"
				# 署名しないゾーンはどうしようか?
#				data += File.read(@outdir+child.manageaddr+"/dsset-"+child.zonename+".")
			end
		end

		return data
	end

        def create_dnskeys
                @kskname = `#{$dnssec_keygen_exec} -K #{@outdir}#{@zonedir}/tmp/namedb/ -r /dev/urandom -f KSK -a RSASHA1 -b 1024 .`
                @zskname = `#{$dnssec_keygen_exec} -K #{@outdir}#{@zonedir}/tmp/namedb/ -r /dev/urandom -a RSASHA1 -b 512 .`
                @kskname = @kskname.chomp
                @zskname = @zskname.chomp
                @kskdata = File.read(@outdir+@zonedir+"tmp/namedb/"+@kskname+".key")
                @zskdata = File.read(@outdir+@zonedir+"/tmp/namedb/"+@zskname+".key")
        end

end

class Tree
	def initialize(nsconfig, outdir)
		# create output directory
		unless File.exist?(outdir)
			Dir.mkdir(outdir)
		end

		@zones = []
		# 設定を引っ張って
		File.open(nsconfig) do |file|
			while line = file.gets
				zone_setting = line.split(nil)
				if (zone_setting[2] == ".")
					@zones << Root.new(zone_setting[0], zone_setting[1], zone_setting[2], zone_setting[3], zone_setting[4], outdir)
				else
					@zones << Zone.new(zone_setting[0], zone_setting[1], zone_setting[2], zone_setting[3], zone_setting[4], outdir)
				end
			end
		end

		search_child_zones
	end

	def save
		zones_sorted = @zones.sort { |a1, a2|
			a2.zonename.length <=> a1.zonename.length
		}
		for zone in zones_sorted do
			zone.save_zonedata
			puts zone.zonedata
		end
	end

private

	def search_child_zones
		# この段階で上位が sign されていない場合非署名にする必要あり
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
		# 短い順（上位ドメイン順）にソート
		zones_sorted = @zones.sort { |a1, a2|
			a1.zonename.length <=> a2.zonename.length
		}
		for zone in zones_sorted do
			if zone.issigned == ""
				zone.child_zones.each do |child|
					child.issigned = ""
				end
			end
		end
	end
end

opterr = false
nsconfig = "nsconfig.txt"
outdir = "zones/"
$no_create_dnskey = false
$dnssec_keygen_exec = '/usr/sbin/dnssec-keygen'
$dnssec_signzone_exec = '/usr/sbin/dnssec-signzone'

open("namelist.txt") {|file| $namelist = file.readlines }


opt = OptionParser.new
opt.on('-n', '--nsconfig=VAL', 'specify ns configuration file') {|v| nsconfig = v}
opt.on('-o', '--outdir=VAL', 'specify output directory name') {|v| outdir = v}
opt.on('-k', '--no-dnskey') {|v| $no_create_dnskey = true }
opt.parse!(ARGV)
if opterr
  STDERR.print opt.help
  exit 1
end

APP_ROOT = Dir.pwd + "/" + File.dirname(__FILE__)
tree = Tree.new(nsconfig, outdir)
tree.save
