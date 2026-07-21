@echo off
REM Description: This is a script to collect several netstat outputs
REM and report them to check_mk as a local used script.
REM GOW linux utilities shoeld be installed on the host
REM
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


REM Or in windows scripting style use:

@echo off
for %%p in (2580 2590 2591) do (
for /f "delims=" %%c in ('netstat -an ^| findstr /v /i LISTENING ^| find /i /c ":%%p "') do (
echo P TCP_Connections_%%p Connections_%%p=%%c Connections: %%c
)
)
