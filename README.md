# AzureAD-Privileged-User-Report
 Extract a list of all the members of Azure privileged roles

## Requirements

This script requires the following modules:

* [MSOnline](https://www.powershellgallery.com/packages/MSOnline/)
* [AzureADPreview](https://www.powershellgallery.com/packages/AzureADPreview/)

## How to use

* Download the script and save it to your computer.
* Login to AzureAD in PowerShell (`Connect-AzureAD`)
* Login to MSOnline in PowerShell (`Connect-MsolService`)
* Run this command to get ALL privileged role members report and display the result on the screen.

```PowerShell
.\Get-AzurePrivilegedRoleReport.ps1 -Verbose
```

* Run this command to get ALL privileged role members report and export the result to a CSV file.

```PowerShell
.\Get-AzurePrivilegedRoleReport.ps1 -Verbose | Export-Csv -NoTypeInformation .\report.csv
```

* Get all the role group members of 'Company Administrators'

```PowerShell
.\Get-AzurePrivilegedRoleReport.ps1 -RoleName 'Company Administator' -Verbose
```

## Example Output

![export all role members](/images/image01.png)<br>
Export all role members to CSV

![csv report](/images/image02.png)<br>
CSV report
