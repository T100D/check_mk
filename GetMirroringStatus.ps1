[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null;
$Server = New-Object "Microsoft.SqlServer.Management.Smo.Server" "localhost";
$Databases = $Server.Databases | Where-Object {$_.IsMirroringEnabled -eq $true}; 
ForEach($Database in $Databases){
    Switch($Database.MirroringStatus){
        "Synchronized"{
        $Output = "0 MirroringStatus_" + $Database.Name + " Status=1 MirroringStatus = "+ $Database.MirroringStatus
        }
        "Synchronizing"{
        $Output = "1 MirroringStatus_" + $Database.Name + " Status=0 MirroringStatus = "+ $Database.MirroringStatus
        }
        default{
        $Output = "2 MirroringStatus_" + $Database.Name + " Status=0 MirroringStatus = "+ $Database.MirroringStatus
        }
    }
    Write-Output $Output
}
