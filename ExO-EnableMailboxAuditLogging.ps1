$ch_env = Get-ChildItem env:

if (!($ch_env.AUTOMATION_ASSET_ACCOUNTID))
    {
    Write "This script is not executed in Azure Automation."
    }

$ch_env.AUTOMATION_ASSET_ACCOUNTID
