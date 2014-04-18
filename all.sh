#!/bin/sh

#usage: all.sh <named_querylog>

rm -rf zones
sh extract_names_fromlog.sh $1

ruby creatensconfig.rb > nsconfig.txt
ruby createzones.rb
