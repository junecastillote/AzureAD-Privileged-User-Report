#Requires -Module MSOnline,AzureADPreview

<#
.SYNOPSIS
	Extract a list of all the members of Azure privileged roles.
.DESCRIPTION
	****************IMPORTANT****************
	This script requires the MSOnline and AzureAdPreview modules.
	Before using the script you must first connect to MSOnline (Connect-MsolService) and AzureAD (Connect-AzureAD)
	*****************************************

	This script will extract a list of all members of Azure directory roles. The report contains several properties such as:
		* UserPrincipalName
		* DisplayName
		* RoleGroup
		* BlockCredential
		* PasswordAge
		* PasswordNeverExpires
		* LastPasswordChange
		* LastLoginDate
		* DaysSinceLastLogIn
		* IsCloudOnlyAccount

.EXAMPLE
	.\Get-AzurePrivilegedRoleReport.ps1 -Verbose
	Get all members of all role groups and display the results on the screen
.EXAMPLE
	.\Get-AzurePrivilegedRoleReport.ps1 -Verbose | Export-Csv -NoTypeInformation .\report.csv
	Get all members of all role groups and export the list to CSV
.EXAMPLE
	.\Get-AzurePrivilegedRoleReport.ps1 -RoleName 'Company Administator' -Verbose
	Get all the role group members of 'Company Administrators'
.INPUTS
	Inputs (if any)
.OUTPUTS
	Output (if any)
.NOTES
	General notes
#>

[cmdletbinding()]
param (
	[parameter()]
	[string]$RoleName
)

## Get today's date
$today = Get-Date

## Get Roles
if ($RoleName) {
	try {
		Write-Verbose "Getting Role : $RoleName"
		$roles = Get-MsolRole -RoleName $RoleName -ErrorAction STOP
	}
	catch {
		Write-Error $_.Exception.Message
		return $null
	}
}
else {
	$roles = Get-MsolRole
}

if ($roles) {
	$finalResult = @()
	## How many role groups are there?
	$rolesCount = $roles.Count
	## Start role group counter
	$i = 1
	foreach ($role in $roles) {
		Write-Verbose "Rolegroup $i/$rolesCount : $($role.Name)";$i = $i + 1
		## Get the members of each role group
		$members = Get-MsolRoleMember -RoleObjectId $role.ObjectID -MemberObjectTypes User | Select-Object ObjectID
		if ($members) {
			$memberCount = $members.Count
			$j = 1
			## Log each member
			foreach ($member in $members) {
				## Build the property collection object
				$temp = "" | Select-Object UserPrincipalName, DisplayName, RoleGroup, BlockCredential, PasswordAge, PasswordNeverExpires, LastPasswordChange, LastLoginDate, DaysSinceLastLogIn, IsCloudOnlyAccount
				## Get user details
				$user = Get-MsolUser -ObjectId ($member.ObjectID) | Select-Object UserPrincipalName, ImmutableID, DisplayName, PasswordNeverExpires, LastPasswordChangeTimestamp, BlockCredential
				Write-Verbose "Rolegroup $($i-1)/$rolesCount [$($role.Name)], Member $j/$memberCount : [$($user.DisplayName)]" ; $j = $j + 1
				## Get user's latest detected login time (WITHIN 30 DAYS ONLY)
				$userLoginTime = (Get-AzureADAuditSignInLogs -Filter "userPrincipalName eq '$($user.UserPrincipalName)'" -Top 1).CreatedDateTime

				## Compose the final result
				$temp.UserPrincipalName = $user.UserPrincipalName
				$temp.DisplayName = $user.DisplayName
				$temp.RoleGroup = $role.Name
				$temp.BlockCredential = $user.BlockCredential
				$temp.PasswordNeverExpires = $user.PasswordNeverExpires
				$temp.LastPasswordChange = (Get-Date $user.LastPasswordChangeTimestamp -Format "dd-MMM-yyyy")
				$temp.PasswordAge = (New-TimeSpan -Start $temp.LastPasswordChange -end $today).Days
				if ($userLoginTime) {
					$temp.LastLoginDate = (Get-Date $userLoginTime -Format "dd-MMM-yyyy")
					$temp.DaysSinceLastLogIn = (New-TimeSpan -Start $temp.LastLoginDate -end $today).Days
				}

				if ($null -eq $user.ImmutableID) {
					$temp.IsCloudOnlyAccount = $true
				}
				else {
					$temp.IsCloudOnlyAccount = $false
				}

				$finalResult += $temp
			}
		}
	}
	return $finalResult
}