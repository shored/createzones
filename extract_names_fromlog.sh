#!/bin/sh

#usage: extract_names_fromlog.sh <bind querylog>

#input: bind querylog
#output: namedlist.txt - all queried names
#output: domainlist.txt - zones which contains all queried names

cat $1 | awk '{print $7}' | grep -v '\\' | sort | uniq > namelist.txt
cat namelist.txt | /usr/bin/ruby  `dirname ${BASH_SOURCE:-$0}`/enumalldomains.rb | sort > domainlist.txt
