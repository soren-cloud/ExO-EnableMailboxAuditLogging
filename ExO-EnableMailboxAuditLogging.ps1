<#PSScriptInfo
.VERSION 1.0.2
.GUID 911b3916-2a11-4e53-977b-3992fc89d977
.AUTHOR Soren Lindevang
.COMPANYNAME
.COPYRIGHT
.TAGS PowerShell Exchange Online Office 365 Logging Logs Audit Auditing Azure Automation
.LICENSEURI
.PROJECTURI
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
#>

<#
.SYNOPSIS
    Enabling mailbox audit log on all Exchange Online mailboxes. Designed for execution in Azure Automation

    No warranties. Use at your own risk.

.DESCRIPTION
    This script enables audit logging for all mailboxes in the connected Exchange Online tenant.

    The audit log level can be configured to either 'full' or 'default' for all tree logon types (Administrator, Delegate, Owner).

    Audit log age can be set as well.

    This script will only work in an Azure Automation runbook.

    Check out the GitHub Repo: https://github.com/soren-cloud/ExO-EnableMailboxAuditLogging

.PARAMETER AuditLogLevel
    Audit log level of all three logon types (Administrator, Delegate, Owner) to be set on all mailboxes.

    Only two valid inputs; 'Default' and 'Full'.

    'Default': The default audit log setting on mailbox creation.

    'Full': All possible actions are logged.

    List of actions to be audit logged: https://technet.microsoft.com/en-us/library/ff459237(v=exchg.160).aspx.

    Default value: 'Default'.

.PARAMETER AuditLogAgeLimit
    Determines how long audit log entries will be retained (in days) on all mailboxes

    Default value: 90.

.PARAMETER AutomationPSCredentialName
    Name of the Automation Credential used when connecting to Exchange Online.

    The Account should at least have "Audit Log" rights in the Exchange Online tenant.

.PARAMETER ForceUpdate
    If this switch is present, the script will force a 'Set' command, regardless of whether the log settings match the desired settings or not.

.PARAMETER EnableVerbose 
     If this switch is present, 'VerbosePreference' will be set to "Continue" in the script.
     
     Build-in Verbose switch is not supported by Azure Automation (yet).
     
     Example 1: true
     Example 2: false

     Default value = false

.INPUTS
    N/A

.OUTPUTS
    N/A

.NOTES
    Version:        1.0.2
    Author:         Soren Greenfort Lindevang
    Creation Date:  24.05.2018
    Purpose/Change: - Set-Mailbox command changed from Pipeline input to $Mailbox.Identity (thx hestmo)

    Version:        1.0.1
    Author:         Soren Greenfort Lindevang
    Creation Date:  15.05.2018
    Purpose/Change: - Added 'EnableVerbose' switch 
                    - Improved error handling
                    - Improved output formatting

    Version:        1.0
    Author:         Soren Greenfort Lindevang
    Creation Date:  30.03.2018
    Purpose/Change: Initial script development
  
.EXAMPLE
    Enable Audit Logging on all mailboxes, at default logging level and default log age limit (90 days)
    ExO-EnableMailboxAuditLogging -AutomationPSCredentialName 'ExchangeServiceAccount'
    
.EXAMPLE
    Enable Audit Logging on all mailboxes, at full logging level and custom log age limit (180 days)
    ExO-EnableMailboxAuditLogging -AuditLogAgeLimit "Full" -AuditLogLevel 180 -AutomationPSCredentialName 'ExchangeServiceAccount'

.EXAMPLE
    Enable Audit Logging on all mailboxes, at full logging level and custom log age limit (365 days). Will force a change to all mailboxes
    ExO-EnableMailboxAuditLogging -AuditLogAgeLimit "Full" -AuditLogLevel 365 -AutomationPSCredentialName 'ExchangeServiceAccount' -ForceUpdate
#>
[cmdletbinding()]
param (
    [Parameter(
        Mandatory=$true)]
        [ValidateSet("Default","Full")]
        [string]$AuditLogLevel = "Default",

    [Parameter(
        Mandatory=$true)]
        [int]$AuditLogAgeLimit = 90,
  
    [Parameter(
        Mandatory=$true)]
        [string]$AutomationPSCredentialName,

    [Parameter(
        Mandatory=$false)]
        [switch]$ForceUpdate,

    [Parameter(
        Mandatory=$false)]
        [switch]$EnableVerbose    
)

#-----------------------------------------------------------[Functions]------------------------------------------------------------

# Test if script is running in Azure Automation
function Test-AzureAutomationEnvironment
    {
    if ($env:AUTOMATION_ASSET_ACCOUNTID)
        {
        Write-Verbose "This script is executed in Azure Automation"
        }
    else
        {
        $ErrorMessage = "This script is NOT executed in Azure Automation."
        Stop-AutomationScript -Status Failed
        }
    }

# Connect to Exchange Online 
function Connect-ExchangeOnline 
    {
    param ($Credential,$Commands)
    try
        {
        Write-Output "Connecting to Exchange Online"
        Get-PSSession | Remove-PSSession       
        $Session = New-PSSession –ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Credential `
            -Authentication Basic -AllowRedirection
        Import-PSSession -Session $Session -DisableNameChecking:$true -AllowClobber:$true -CommandName $Commands | Out-Null
        }
    catch 
        {
        Write-Error -Message $_.Exception
        Stop-AutomationScript -Status Failed
        }
    Write-Verbose "Successfully connected to Exchange Online"
    }

# Disconnect to Exchange Online 
function Disconnect-ExchangeOnline 
    {
    try
        {
        Write-Output "Disconnecting from Exchange Online"
        Get-PSSession | Remove-PSSession       
        }
    catch 
        {
        Write-Error -Message $_.Exception
        Stop-AutomationScript -Status Failed
        }
    Write-Verbose "Successfully disconnected from Exchange Online"
    }

# Stop Automation Script
function Stop-AutomationScript
    {
    param(
        [ValidateSet("Failed","Success")]
        [string]
        $Status = "Success"
        )
    Write-Output ""
    Disconnect-ExchangeOnline
    if ($Status -eq "Success")
        {
        Write-Output "Script successfully completed"
        }
    elseif ($Status -eq "Failed")
        {
        Write-Output "Script stopped with an Error"
        }
    Break
    }

#----------------------------------------------------------[Declarations]----------------------------------------------------------

if ($AuditLogLevel -eq "Default")
    {
    $AuditOwner = "UpdateFolderPermissions"
    $AuditAdmin = "Create","FolderBind","HardDelete","Move","MoveToDeletedItems","SendAs","SendOnBehalf","SoftDelete","Update","UpdateFolderPermissions"
    $AuditDelegate = "Create","HardDelete","SendAs","SoftDelete","Update","UpdateFolderPermissions"
    }
elseif ($AuditLogLevel -eq "Full")
    {
    $AuditOwner = "Create","HardDelete","MailboxLogin","Move","MoveToDeletedItems","SoftDelete","Update","UpdateFolderPermissions"
    $AuditAdmin = "Copy","Create","FolderBind","HardDelete","MessageBind","Move","MoveToDeletedItems","SendAs","SendOnBehalf","SoftDelete","Update","UpdateFolderPermissions"
    $AuditDelegate = "Create","FolderBind","HardDelete","Move","MoveToDeletedItems","SendAs","SendOnBehalf","SoftDelete","Update","UpdateFolderPermissions"
    }

#-----------------------------------------------------------[Execution]-----------------------------------------------------------

Test-AzureAutomationEnvironment

Write-Output "::: Parameters :::"
Write-Output "AuditLogAgeLimit:           $AuditLogAgeLimit"
Write-Output "AuditLogLevel:              $AuditLogLevel"
Write-Output "ForceUpdate:                $ForceUpdate"
Write-Output "AutomationPSCredentialName: $AutomationPSCredentialName"
Write-Output "EnableVerbose:              $EnableVerbose"
Write-Output ""

# Handle Verbose Preference
if ($EnableVerbose -eq $true)
    {
    $VerbosePreference = "Continue"
    }

# Get AutomationPSCredential
Write-Output "::: Connection :::"
try
    {
    Write-Output "Importing Automation Credential"
    $Credentials = Get-AutomationPSCredential -Name $AutomationPSCredentialName -ErrorAction Stop
    }
catch 
    {
    Write-Error -Message $_.Exception
    Stop-AutomationScript -Status Failed
    }
Write-Verbose "Successfully imported credentials"

# Connect to Exchange Online
Connect-ExchangeOnline -Credential $Credentials -Commands "Set-Mailbox","Get-Mailbox"
Write-Output ""

Write-Verbose "::: Import Mailboxes :::"
# Get All Mailboxes (UserMailbox, SharedMailbox, EquipmentMailbox, RoomMailbox)
try
    {
    Write-Verbose "Importing list of mailboxes"
    $Mailboxes = Get-Mailbox -RecipientTypeDetails UserMailbox,SharedMailbox,EquipmentMailbox,RoomMailbox,DiscoveryMailbox -ErrorAction Stop
    }
catch 
    {
    Write-Error -Message $_.Exception
    Stop-AutomationScript -Status Failed
    }
Write-Verbose "Successfully imported list of mailboxes"

if (!$Mailboxes)
    {
    $ErrorMessage = "No mailboxes found!"
    Stop-AutomationScript -Status Failed
    }

# Filter mailboxes in scope for processing
$LogAgeTimeSpan = New-TimeSpan -Days $AuditLogAgeLimit
if ($ForceUpdate)
    {
    $MailboxesToProcess = $Mailboxes
    }
else
    {
    try
        {
        Write-Verbose "Filtering mailboxes in scope for processing"
        $MailboxesToProcess = $Mailboxes | Where-Object {($_.AuditLogAgeLimit -ne $LogAgeTimeSpan) -or (Compare-Object $_.AuditOwner $AuditOwner) -or `
            (Compare-Object $_.AuditAdmin $AuditAdmin) -or (Compare-Object $_.AuditDelegate $AuditDelegate)}
        }
    catch 
        {
        Write-Error -Message $_.Exception
        Stop-AutomationScript -Status Failed
        }
    Write-Verbose "Successfully filtered mailboxes"
    }
Write-Verbose ""

#Process Mailboxes
Write-Output "::: Process Mailboxes :::"
Write-Output "Mailboxes to process: $($MailboxesToProcess.count)"
$count = $null
Foreach ($Mailbox in $MailboxesToProcess)
    {
    try
        {
        $count++
        Write-Verbose "Mailbox: $count/$($MailboxesToProcess.count) - $($Mailbox.UserPrincipalName)"
        Set-Mailbox -Identity $Mailbox.UserPrincipalName -AuditEnabled $true -AuditOwner $AuditOwner -AuditAdmin $AuditAdmin -AuditDelegate $AuditDelegate `
            -AuditLogAgeLimit $AuditLogAgeLimit -Force
        }
    catch 
        {
        Write-Error -Message $_.Exception
        }
    }
Write-Verbose "Processing completed"

Stop-AutomationScript -Status Success
