# Connect to your environment
Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
CD DEV:
# Import some demo computer objects
Import-Csv C:\Demos\UDA\ImportData.csv | % {Import-CMComputerInformation -ComputerName "$($_.NetbiosName)" -MacAddress "$($_.Mac)" -CollectionName "DEV-MC-Imports"}


# Query to export all UDA data

$ExportUDA = @"
  --Get UDA Data
  SELECT umr.[MachineResourceName],umr.[UniqueUserName],umr.[RelationshipResourceID]
  FROM [dbo].[v_UserMachineRelationship] umr
  inner join [dbo].[v_UserMachineSourceRelation] umsr on umr.RelationshipResourceID=umsr.RelationshipResourceID
  Where umr.RelationActive = 1 AND umsr.SourceID = 2
"@

# Export All UDA Type 2 Data to C:\Demos\UDA\AllExportedData.csv
invoke-sqlcmd -ServerInstance localhost -Database 'CM_DEV' -Query $ExportUDA | Export-Csv C:\Demos\UDA\AllExportedDataDemo.csv -NoTypeInformation

# Remove All UDA Type 2 Data
invoke-sqlcmd -ServerInstance localhost -Database 'CM_DEV' -Query $ExportUDA | % { Remove-CMUserAffinityFromDevice -DeviceName "$($_.MachineResourceName)" -UserName "$($_.UniqueUserName)" -Force }





# UDA PS cmdlets https://technet.microsoft.com/en-us/library/jj821832(v=sc.20).aspx (Set, Get, Remove, Import)
# Add a relationship
Add-CMUserAffinityToDevice -DeviceName "TRDB0004" -UserName "test\sjesok"
Add-CMUserAffinityToDevice -DeviceName "TRDB0004" -UserName "test\sjesok-a"

# Get a relationship
[array]$uda = Get-CMUserDeviceAffinity -DeviceName "TRDB0004"

# Remove a relationship
Remove-CMUserAffinityFromDevice -DeviceName "TRDB0004" -UserName "test\jesok" -Force

# Set user device affinity in a function
Function Set-SCCMDeviceAffintity {
<#
    .SYNOPSIS
        Used to set user device affinity between a given device and user.

    .DESCRIPTION
        The function will set user device affinity for a specific user an computer.  As part of this action, existing UDA type 2 relationships are removed.

    .PARAMETER ComputerName	
        Mandatory the computername .
       
    .PARAMETER UserName
        Mandatory the unique user name represented as 'domain\username'
 
    .EXAMPLE
        Set administrative user device affinity for a given system and user.
    
        Set-SCCMDeviceAffintity -ComputerName 'hostname' -UserName 'domain\username'

    .NOTES
        Author  : Nash Pherson
        Email   : nashp@nowmicro.com
        Twitter : @KidMysic
        Feedback: Please send feedback!  This is my first real attempt publishing/sharing a powershell script!
        Blog    : http://blog.nowmicro.com/category/nash-pherson/
        Blog    : http://windowsitpro.com/author/nash-pherson
        
    .LINK
        http://gallery.technet.microsoft.com/scirptscenter/ PUT THE GUID HERE

#>
    param([string]$UserName,[string]$ComputerName)

    If (Get-CMUser -Name $UserName) {
        if (Get-CMDevice -Name $ComputerName) {
            # Query and remove existing assignments
            [array]$da = Get-CMUserDeviceAffinity -DeviceName $ComputerName
            if ($da.count -ge 1) {
                try {
                    Foreach ($d in $da) {
                        Remove-CMUserAffinityFromDevice -DeviceName "$($d.ResourceName)" -UserName "$($d.UniqueUserName)" -Force
                        Write-Host "Remove user relationship type 2 for user $($d.UniqueUserName) on device $($d.ResourceName)" -ForegroundColor Green
                    }
                } Catch {
                    Write-Error "Error removing device affinity for user $($da.UniqueUserName) on device $($da.ResourceName)."
                }
            }
            #Set new assignment
            try {
                Add-CMUserAffinityToDevice -DeviceName $ComputerName -UserName $UserName
                Write-Host "Created user relationship type 2 for user $UserName on device $ComputerName" -ForegroundColor Yellow
            } catch {
                Write-Error "Error assigning affinity"
            }
        } else {
         Write-Error "Computer $computername was not found."
        }
    } else {
        Write-error "User $username was not found"
    }
}

#$VerbosePreference = SilentlyContinue

# the function ensures a system is only assigned to a single user
Set-SCCMDeviceAffintity -username "test\sjesok" -computername "TRDB0004"

#Assign a bunch of systems
Import-Csv C:\Demos\UDA\ImportData.csv | % {Set-SCCMDeviceAffintity -computername "$($_.MachineResourceName)" -UserName "$($_.UniqueUserName)"}

# Collection Magic

# Collection query for single user example
New-CMDeviceCollection -LimitingCollectionName "All Systems" -Name "DEV-UDA-All My Systems"

$CollQuery = @"
select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System  
INNER JOIN SMS_UserMachineRelationship ON SMS_R_System.ResourceID=SMS_UserMachineRelationship.MachineResourceID  
Where SMS_UserMachineRelationship.Sources = "2"
AND SMS_UserMachineRelationship.UniqueUserName IN  
 (select SMS_R_USER.UniqueUserName from SMS_R_User where SMS_R_User.UniqueUserName = "TEST\\sjesok")
"@
Add-CMDeviceCollectionQueryMembershipRule -CollectionName "DEV-UDA-All My Systems" -QueryExpression $CollQuery -RuleName "All Jesok Systems"

# Use an AD Group example

New-CMDeviceCollection -LimitingCollectionName "All Systems" -Name "DEV-UDA-CMGROUP1"
$CollQuery = @"
select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System  
INNER JOIN SMS_UserMachineRelationship ON SMS_R_System.ResourceID=SMS_UserMachineRelationship.MachineResourceID  
Where SMS_UserMachineRelationship.Sources = "2"
AND SMS_UserMachineRelationship.UniqueUserName IN  
 (select SMS_R_USER.UniqueUserName from SMS_R_User where SMS_R_User.UserGroupName = "TEST\\CMGROUP1") 
"@
Add-CMDeviceCollectionQueryMembershipRule -CollectionName "DEV-UDA-CMGROUP1" -QueryExpression $CollQuery -RuleName "CMGROUP1"

#Department Collections based on discovery data from AD
$departments = invoke-SQLCMD -ServerInstance "msphq15cme01" -Database "CM_DEV" -Query "select distinct department0 from v_R_User where department0 IS NOT NULL"
CD DEV:
$departments | % {
New-CMDeviceCollection -LimitingCollectionName "All Systems" -Name "DEV-UDA-Departments $($_.department0)"
$CollQuery = @"
select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System  
INNER JOIN SMS_UserMachineRelationship ON SMS_R_System.ResourceID=SMS_UserMachineRelationship.MachineResourceID  
Where SMS_UserMachineRelationship.Sources = "2"
AND SMS_UserMachineRelationship.UniqueUserName IN  
 (select SMS_R_USER.UniqueUserName from SMS_R_User where SMS_R_User.department = "$($_.department0)") 
"@

Add-CMDeviceCollectionQueryMembershipRule -CollectionName "DEV-UDA-Departments $($_.department0)" -QueryExpression $CollQuery -RuleName "$($_.department0) Dept"
}

Get-CMDeviceCollection -Name "DEV-UDA-*" | Remove-CMDeviceCollection -Force


