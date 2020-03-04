<# 
     .SYNOPSIS 
     This script will install an AD integrated certificate authority with web enrollment in your lab
#>

#Requires -Version 3
#Requires -RunAsAdministrator

###
### Variables
###
$CACommonName = 'dominik-lab-CA'
$HashAlgorithmName = 'SHA256'
$KeyLength = 2048
$PeriodOfValidity = 10 #in years

###
### Script
###
Try
{
    Install-WindowsFeature -Name AD-Certificate -IncludeManagementTools
    Install-AdcsCertificationAuthority -HashAlgorithmName SHA256 -KeyLength $KeyLength -ValidityPeriod Years -ValidityPeriodUnits $PeriodOfValidity -CACommonName $CACommonName -CAType EnterpriseRootCA -Verbose -Force
    
    Add-WindowsFeature ADCS-Web-Enrollment
    Install-AdcsWebEnrollment -Force
}
Catch
{
    Throw $_
}
