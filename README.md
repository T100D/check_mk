# check_mk
Files created for monitoring with check_mk

  - login.bat - (windows) - Check for windows hosts to see if anyone is logged in  
  - fileage.ps1 - (windows) - Check last write timestamp on a file. Problem is that MS does not regular updates the timestamp :-(  
  - netstat-collector.bat - (windows) - Collects TCP statistics, requires GOW to work  
  - GetMirroringStatus.ps1 - (windows) - Locak check - Monitor Mirroring Status on SQL servers.
  - cleansimple.sh - Cleanup script for docuwiki
  - netstat_an.bat - For windows netstat check on sinlge item (RDP)
  - mk_logwatch.py3 - Fixed mk_logwatch from check_mk 1.2.8p27 to work under python3
  - check-status.cloud.microsoft.sh - Script to read the contents of the webpage and store it locally
  - mk_check-status.cloud.microsoft - Checht to read the contents of the above file and present it locally
  - Get-MSSQL.ps1 from: https://github.com/Fishy78/checkmk-mssql/blob/main/Get-MSSQL.ps1
