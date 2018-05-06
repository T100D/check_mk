'''
@echo off
set command="netstat -an | grep <ip-addres> | wc -l"
for /f "delims=" %%c in ('%command%') do (
echo P TCP_Connecties_WEBSITE Count=%%c;50
)

set command="netstat -an | grep 1521 | wc -l"
for /f "delims=" %%c in ('%command%') do (
echo P TCP_Connecties_Database Count=%%c;50
)

set command="netstat -an | grep <ip-addres> | wc -l"
for /f "delims=" %%c in ('%command%') do (
echo P TCP_Connecties_Server Count=%%c;50
)
'''
