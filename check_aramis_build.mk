#
# Created by Arie
# Script om het aramis buils nummer uit te lezen
#
# Date 26-01-2026
#
# Get the build number from eval aramis and put the number in a file
echo 'QUIT' | nc -w 1  127.0.0.1 51555 > /tmp/aramis.txt
#
# Get the build number
build=$(cat /tmp/aramis.txt | grep build)
#
# Report the number to Check_mk
echo "0 ARAMIS_Build - ARAMIS Build =$build"
