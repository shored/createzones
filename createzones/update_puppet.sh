#!/bin/sh

cp -R /home/garit/createzones/zones/* /etc/puppet/modules/authoritative/named
chown -R puppet /etc/puppet/modules/authoritative/named/*

killall -1 puppet

gsh authoritative 'killall -1 puppet'
sleep 15
gsh authoritative 'killall -1 named'
