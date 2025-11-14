#!/bin/bash
#
# Script om aantal deleted secties in een memorymap bij te houden
# Door Arie van den Heuve
# 14-11-2025
#
#Verzamelen totaal aantal mapped items
total=$(mypid=$(pidof /opt/vtmis/ARAMIS/bin/x86_64-linux-gnu/aramis) ; pmap -x $mypid | wc -l)
# Verzamelen aantal deleted items
deleted=$(mypid=$(pidof /opt/vtmis/ARAMIS/bin/x86_64-linux-gnu/aramis) ; pmap -x $mypid | grep deleted | wc -l)
# Rapportage aan de monitoring
echo "<<<local>>>"
echo "P pmap_deleted Count=$deleted;500"
echo "P pmap_total Count=$total;5000"
