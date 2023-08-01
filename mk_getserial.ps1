# script to report the hardware serial number
# written by Arie van den Heuvel
# 31-07-2023
# get the serial number
$serialnumber = (Get-WmiObject win32_bios | select -ExpandProperty Serialnumber)
#
# report the serial number to check_mk
echo "<<<local>>>"
echo "0 HW_Serialnumber - Hardware Serial Number=$serialnumber"