@echo off
set command="query session | find /C "Active""
for /f "delims=" %%c in ('%command%') do (
echo P Logins count=%%c;0;1 %%c logins on system
)
