<# 
     .SYNOPSIS 
     This script will install Microsoft SQL Server 2014 in your lab.
#>

#Requires -Version 3
#Requires -RunAsAdministrator

###
### Variables
###
$SAPWD = Read-Host 'Enter the password for the SQL sa user'
$SQLSysAdminAccounts = "$env:USERDOMAIN\SQL_Admins" # AD user or group that will get SQL administrator
$PathToSetup = 'D:\setup.exe'

###
### Script
###
Try
{
    Test-Path $PathToSetup -ErrorAction Stop
    Write-Output 'Adding Windows Feature .Net Framework'
    Add-WindowsFeature net-framework-core -ErrorAction Stop
    
$ini=@"
;SQL Server 2014 Configuration File
[OPTIONS]
ACTION="Install"
ENU="True"
IACCEPTSQLSERVERLICENSETERMS="True"
QUIET="False"
QUIETSIMPLE="True"
UpdateEnabled="True"
ERRORREPORTING="False"
USEMICROSOFTUPDATE="True"
FEATURES=SQLENGINE,SSMS,ADV_SSMS
UpdateSource="MU"
HELP="False"
INDICATEPROGRESS="False"
X86="False"
INSTALLSHAREDDIR="C:\Program Files\Microsoft SQL Server"
INSTALLSHAREDWOWDIR="C:\Program Files (x86)\Microsoft SQL Server"
INSTANCENAME="MSSQLSERVER"
SQMREPORTING="False"
INSTANCEID="MSSQLSERVER"
INSTANCEDIR="C:\Program Files\Microsoft SQL Server"
AGTSVCACCOUNT="NT Service\SQLSERVERAGENT"
AGTSVCSTARTUPTYPE="Manual"
COMMFABRICPORT="0"
COMMFABRICNETWORKLEVEL="0"
COMMFABRICENCRYPTION="0"
MATRIXCMBRICKCOMMPORT="0"
SQLSVCSTARTUPTYPE="Automatic"
FILESTREAMLEVEL="0"
ENABLERANU="False"
SQLCOLLATION="Latin1_General_CI_AS"
SQLSVCACCOUNT="NT Service\MSSQLSERVER"
SQLSYSADMINACCOUNTS="$SQLSYSADMINACCOUNTS"
SECURITYMODE="SQL"
SAPWD="$SAPWD"
ADDCURRENTUSERASSQLADMIN="False"
TCPENABLED="1"
NPENABLED="0"
BROWSERSVCSTARTUPTYPE="Disabled"
"@
    New-Item -Path $env:TEMP -Name 'configuration.ini' -ItemType File -Force
    Set-Content -Value $ini -Path "$env:TEMP\configuration.ini" -Force

    Write-Output 'Starting installation. Go and grab a coffee.'
    Start-Process -FilePath $PathToSetup -ArgumentList "/ConfigurationFile=`"$env:TEMP\configuration.ini`"" -Wait
    Remove-Item -Path "$env:TEMP\configuration.ini" -Force    
}
Catch
{
    Throw $_
}
