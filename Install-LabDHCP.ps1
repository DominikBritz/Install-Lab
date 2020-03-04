<#
    .SYNOPSIS
    This script will set up a DHCP server and authorize it in your AD
#>

#Requires -Version 3
#Requires -RunAsAdministrator

###
### Variables
###
$DNSDomain = 'dominik.lab'
$DNSServerIP = '192.168.137.100'
$DHCPServerIP = '192.168.137.100'
$StartRange = '192.168.137.101'
$EndRange = '192.168.137.254'
$Subnet = '255.255.255.0'
$Router = '192.168.137.1'
$LeaseDuration = '1.00:00:00'

###
### Script
###
Try
{
    Install-WindowsFeature -Name 'DHCP' –IncludeManagementTools
    Start-Process -FilePath cmd.exe -ArgumentList "/c 'netsh dhcp add securitygroups'" -Wait    
    Restart-service dhcpserver
    Add-DhcpServerInDC -DnsName $Env:COMPUTERNAME
    Set-ItemProperty –Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 –Name ConfigurationState –Value 2 #Notify the Server Manager that the post-install configuration has been completed successfully
    Add-DhcpServerV4Scope -Name 'DHCP Scope' -StartRange $StartRange -EndRange $EndRange -SubnetMask $Subnet
    Set-DhcpServerV4OptionValue -DnsDomain $DNSDomain -DnsServer $DNSServerIP -Router $Router                   
    Set-DhcpServerv4Scope -ScopeId $DHCPServerIP -LeaseDuration $LeaseDuration
}
Catch
{
    Throw $_
}
