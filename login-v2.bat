@echo off
REM Local check to check if theire are active users on a system
REM Improoved version after checking with ChatGPT
REM
REM Count the number of active logins
for /f "delims=" %%c in ('query session ^| find /C "Active"') do (
  set count=%%c
)
REM Prepair the active query to check_mk
for /f "delims=" %%c in ('%command%') do (
echo P Logins count=%%c;0;1 %%c logins on system
)
