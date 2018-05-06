'''
$file = ‘c:\logfile.log'
   if (Test-Path $file -OlderThan (Get-Date).Addminutes(-150))
    {  "1 LOGFILE_LOG = logfile.log not updated for at least 2,5 hours"}
    Else
    {  "0 LOGFILE_LOG = logfile.log updated”}
'''
