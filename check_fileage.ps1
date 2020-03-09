$file = 'W:\Shares\xxx.log'
   if (Test-Path $file -OlderThan (Get-Date).Addminutes(-60))
    {  "1 IVS_LOG_PROD = IVSLOG.log WESP Productie is not updated for at least one our"}
    Else
    {  "0 IVS_LOG_PROD = IVSLOG.log WESP Productie is updated"}
