<# 
     .SYNOPSIS 
     This script will install MDT and Windows Deployment Services with all the prerequisites in your lab
#>

#Requires -Version 3
#Requires -RunAsAdministrator

###
### Variables
###
$ADKDownloadURL = 'https://go.microsoft.com/fwlink/p/?linkid=859206' # This is the URL for Windows ADK 10 v1709. You can provide another URL if you like.
$ADKOfflinePath = 'C:\install\adkSetup.exe' # The path to the ADK offline installer. If the variable is filled then the script will ignore the variable $ADKDownloadURL

$MDTDownloadURL = 'https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi' # This is the URL for MDT 8443. You can provide another URL if you like.
$MDTDeploymentShareFolder = 'E:\DeploymentShare'
$MDTDeploymentShareName = 'DeploymentShare'
$MDTChocolateyApplications = @('7zip','citrix-receiver','googlechrome','notepadplusplus','putty','snaketail','sysinternals','WinSCP') # You need a chocolatey wrapper in order for this to work https://keithga.wordpress.com/2014/11/25/new-tool-chocolatey-wrapper-for-mdt/

$WDSRemoteInstallFolder = 'E:\RemoteInstall'

$ErrorActionPreference = 'Stop'

###
### Script
###
Try
{
    If ($ADKOfflinePath)
    {
        Write-Output 'Installing ADK 10 Offline'        
        Start-Process -FilePath $ADKOfflinePath -ArgumentList '/norestart /q /ceip off /features OptionId.WindowsPreinstallationEnvironment OptionId.DeploymentTools OptionId.UserStateMigrationTool' -Wait
    }
    Else
    {
        Write-Output 'Installing ADK 10 Online'
        Invoke-WebRequest $ADKDownloadURL -OutFile $(Join-Path $env:TEMP 'AdkSetup.exe')
        Start-Process -FilePath $(Join-Path $env:TEMP 'AdkSetup.exe') -ArgumentList '/norestart /q /ceip off /features OptionId.WindowsPreinstallationEnvironment OptionId.DeploymentTools OptionId.UserStateMigrationTool' -Wait
    }
    Write-Output 'Adding Windows feature NET-Framework-Core'
    Add-WindowsFeature NET-Framework-Core

    Write-Output 'Adding Windows feature Windows Deployment System'
    Add-WindowsFeature WDS -IncludeManagementTools

    Write-Output 'Installing MDT'
    Invoke-WebRequest $MDTDownloadURL -OutFile $(Join-Path $env:TEMP 'MicrosoftDeploymentToolkit2013_x64.msi')
    Start-Process -FilePath msiexec.exe -ArgumentList "/i $(Join-Path $env:TEMP 'MicrosoftDeploymentToolkit2013_x64.msi') /qn" -Wait
    
    Write-Output 'Setting up MDT'
    mkdir $MDTDeploymentShareFolder
    $Share = [wmiClass]'Win32_share'
    $Share.create($MDTDeploymentShareFolder,$MDTDeploymentShareName,0)
   
    Import-Module 'C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1' -Force    
    New-PSDrive -Name 'DS001' -PSProvider 'MDTProvider' -Root $MDTDeploymentShareFolder -NetworkPath "\\$env:COMPUTERNAME\$MDTDeploymentShareName" -Description 'DeploymentShare' -Verbose | Add-MDTPersistentDrive -Verbose
    New-Item -path 'DS001:\Operating Systems' -enable 'True' -Name 'Windows10' -Comments '' -ItemType folder -Verbose
    New-Item -path 'DS001:\Operating Systems' -enable 'True' -Name 'Windows2012R2' -Comments '' -ItemType folder -Verbose
    New-Item -path 'DS001:\Task Sequences' -enable 'True' -Name 'Windows10' -Comments '' -ItemType folder -Verbose
    New-Item -path 'DS001:\Task Sequences' -enable 'True' -Name 'Windows2012R2' -Comments '' -ItemType folder -Verbose
    $MDTChocolateyApplications | % {
        $Package = $_
        $Path = "powershell.exe -NoProfile -ExecutionPolicy unrestricted `"%ScriptRoot%\Install-Chocolatey.ps1`" -verbose -Packages `"$Package`""
        Import-MDTApplication -path "DS001:\Applications" -Name $Package -ShortName $Package -NoSource -CommandLine $Path -Enable $true
     }
    Update-MDTDeploymentShare -path 'DS001:' –Verbose

    Write-Output 'Setting up WDS'
    Start-Process -FilePath WDSUTIL -ArgumentList "/Initialize-Server /RemInst:`"$WDSRemoteInstallFolder`"" -Wait
    Stop-Service WDSServer -ErrorAction SilentlyContinue
    Start-Service WDSServer
    Import-WdsBootImage -NewImageName 'Lite Touch Windows PE (x64)' -path $(Join-Path $MDTDeploymentShareFolder 'Boot\LiteTouchPE_x64.wim')
    Import-WdsBootImage -NewImageName 'Lite Touch Windows PE (x86)' -path $(Join-Path $MDTDeploymentShareFolder 'Boot\LiteTouchPE_x86.wim')

}
Catch
{
    Throw $_
}
