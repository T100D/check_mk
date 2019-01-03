@echo off
echo ^<^<^<win_netstat^>^>^>
netstat -anp TCP | find ":3389"
