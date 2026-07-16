#
# Created by Arie
# Script to read the export and state the build number of a programm
#
# Date 26-01-2026 Initial version
# Date 16-07-2026 Rewritten to get the number to a memory based check
#
# Get the build number from eval-aramis and put the number in a file
build=$(echo 'QUIT' | nc -4 -w 1  127.0.0.1 51555 | grep build)
#
#
# Report the build number to Check_mk
echo "0 ARAMIS_Build - ARAMIS Build =$build"
