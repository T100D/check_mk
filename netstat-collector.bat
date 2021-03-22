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


Or in windows style:

@echo off
for %%p in (2580 2590 2591) do (
for /f "delims=" %%c in ('netstat -an ^| findstr /v /i LISTENING ^| find /i /c ":%%p "') do (
echo P TCP_Connections_%%p Connections_%%p=%%c Connections: %%c
)
)
