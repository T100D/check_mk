#
# This script tells if a requierd reboot is pending after the system is beeing updated
#
$Reboot = $False
If((Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber).BuildNumber -ge 6001){
    If(Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"){
        $Reboot = $True
    }
}
If(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"){
    If((Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired").Property.Count -gt 0){
        $Reboot = $True
    }
}
If(Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations"){
    If((Get-Item "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations").Property.Count -gt 0){
        $Reboot = $True
    }
}
If($Reboot){
    Write-Host 1 Reboot - A software update installation is awaiting a system restart.
}Else{
    Write-Host 0 Reboot - A system restart is currently not required.
}
