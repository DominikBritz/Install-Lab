<# 
     .SYNOPSIS 
     This script will set up a central GPO store in your lab
#>

#Requires -Version 3
#Requires -RunAsAdministrator

###
### Script
###
Try
{
  New-Item -Path "\\$env:userdnsdomain\SYSVOL\$env:userdnsdomain\policies\PolicyDefinitions" -ItemType Directory -Force -ErrorAction Stop
  Copy-Item -Path "$env:LOGONSERVER\c$\Windows\PolicyDefinitions\*" -Destination "\\$env:userdnsdomain\SYSVOL\$env:userdnsdomain\policies\PolicyDefinitions" -Recurse -ErrorAction Stop
}
Catch
{
  Throw $_
}
