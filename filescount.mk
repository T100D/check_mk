#!/bin/bash
#
## Script to count the total number of files in a given directory, and set an alert level
## Intended for linux systems
## Situated in: /usr/lib/check_mk_agent/local$
#
# Created: 15-01-2026
# Created by: Arie van den Heuvel
#
# Get the numer of files:
files=$(ls -AR /usr/share/saab/maritimecontrol/aisoperationsserver/ais/ | wc -l)
#
# Reporting the items and location identifier to check_mk
echo "<<<local>>>"
echo "P aisoperator_files Count=$files;12000"
