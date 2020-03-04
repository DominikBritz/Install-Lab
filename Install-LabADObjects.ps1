<# 
     .SYNOPSIS 
     This script will set up OUs, groups and users in your domain. The configuration is stored in csv files.
#>

#Requires -Version 3
#Requires -RunAsAdministrator

#region Variables
PARAM
(
    $Domain = 'DC=dominik,DC=lab',
    $PathToOUsCSV = ".\OUs.csv",
    $PathToGroupsCSV = ".\Groups.csv",
    $PathToUsersCSV = ".\Users.csv",
    $OUProtected = $False,
    $UserPassword = (Read-Host 'Enter the password for you user accounts' -AsSecureString)
)
#endregion

#region Script
Write-Output 'Processing OUs'
$OUs = Get-Content -Path $PathToOUsCSV
Foreach ($OU in $OUs) {
    $OUPath = $null        
    If ($OU -notmatch ';')
    {
        $OUName = $OU
        $OUPath = $Domain       
    }
    Else
    {
        $reverse = $OU.split(';')
        [array]::Reverse($reverse)
        $OUName = $reverse[0]
        $reverse = $reverse[1 .. $reverse.Length]   
        Foreach ($item in $reverse) {
        $OU = 'OU=' + $item + ','
        $OUPath += $OU
        }
        $OUPath = $OUPath + $Domain
    }    
    New-ADOrganizationalUnit -Name $OUName -Path $OUPath -ProtectedFromAccidentalDeletion $OUProtected -Verbose
}

Write-Output 'Processing Groups'
$Groups = Import-CSV -Path $PathToGroupsCSV -Delimiter ';'
Foreach ($Group in $Groups) {
    $Path = $ExecutionContext.InvokeCommand.ExpandString($Group.Path)
    New-ADGroup -Name $Group.Name -GroupCategory $Group.Category -GroupScope $Group.Scope -Path $Path -Verbose
}

Write-Output 'Processing Users'
$Users = Import-Csv -Path $PathToUsersCSV -Delimiter ';'
Foreach ($User in $Users) {
    $Path = $ExecutionContext.InvokeCommand.ExpandString($User.Path)    
    New-ADUser -Name $User.Name -Path $Path -Enabled $true -CannotChangePassword $true -ChangePasswordAtLogon $False -PasswordNeverExpires $true -AccountPassword $UserPassword -Verbose 
    
    If ($User.MemberOf) 
    {
        Add-ADGroupMember -Identity $User.MemberOf -Members $User.Name
    }
}
#endregion
