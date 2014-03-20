#!/bin/sh

cat $1 | awk '{print $7}' | sort | uniq | /usr/bin/ruby enumalldomains.rb | sort
