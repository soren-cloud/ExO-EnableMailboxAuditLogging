ExO-EnableMailboxAuditLogging
===========
Script for Azure Automation to enable and configure audit logging on all mailboxes in an Exchange Online tenant.

This script was developed as part of a blog [article] on [soren.cloud].

*Note: This script is designed for execution in a Azure Automation runbook!*


## Requirements
* Office 365 tenant with Exchange Online mailboxes 
 
* Azure Subscription


## Prerequisites
* Enable Office 365 Audit logging (if not already enabled)

    How to: [Link to guide]
* Create Exchange Online Service Account

    Must at least have global "Audit Log" rights

## Usage
Copy the content of the script into a Azure Automation PowerShell Runbook. Then test and deploy (schedule) :-)

**Disclaimer: No warranties. Use at your own risk.**

## Parameters
* **-AuditLogLevel**, Audit log level of all three logon types (Administrator, Delegate, Owner) to be set on all mailboxes. Only two valid inputs; 'Default' and 'Full'.
* **-AuditLogAgeLimit**, Determines how long audit log entries will be retained (in days) on all mailboxes. Default value is 90.
* **-AutomationPSCredentialName**, Name of the Automation Credential used when connecting to Exchange Online.
* **-ForceUpdate**, If this switch is present, the script will force a 'Set' command, regardless of whether the log settings match the desired settings or not.

## Examples
*Remember: This script is designed for execution in a Azure Automation runbook!*

`AuditLogLevel: Default`, `AuditLogAgeLimit: 90`, `AutomationPSCredentialName: Exchange Online Service Account`

Enable mailbox auditing on all mailboxes, retain default level logs in 90 days, and connect with service account 'Exchange Online Service Account'

`AuditLogLevel: Full`, `AuditLogAgeLimit: 180`, `AutomationPSCredentialName: Exchange Online Service Account` `ForceUpdate: True`

Enable mailbox auditing on all mailboxes, retain full level logs in 180 days, and connect with service account 'Exchange Online Service Account'. Force an update.

## More Information
Article: <http://soren.cloud/>


## Credits
Written by: Søren Lindevang

Find me on:

* My Blog: <http://soren.cloud/>
* Twitter: <https://twitter.com/SorenLindevang>
* LinkedIn: <https://www.linkedin.com/in/lindevang/>
* GitHub: <https://github.com/soren-cloud>

[article]: http://soren.cloud/
[my blog]: http://soren.cloud/
[soren.cloud]: http://soren.cloud/
[Link to guide]: https://support.office.com/en-us/article/turn-office-365-audit-log-search-on-or-off-e893b19a-660c-41f2-9074-d3631c95a014