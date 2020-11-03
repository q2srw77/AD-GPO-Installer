# -----------------------------------------------------------------------------------------------
# Component: Sophos Central Installer
# Author: Stephen Weber
# Purpose: Deploy Sophos Central via Active Directory GPO using PowerShell.
# Script Log Location: c:\temp\SophosCentralInstallLog.txt
# Version 1.0
# -----------------------------------------------------------------------------------------------

#Define the SophosSetup.exe Installer Location
#
#SophosSetup.exe needs to be downloaded from the Sophos Central Admin Dashboard, not the partner centre
#
# Example Usage
# $InstallerLocation = "\\server\share\SophosSetup.exe"
# $InstallerArguments = "--messagerelay="192.168.0.1:8190""
#
#Command Line Options can be found here - https://support.sophos.com/support/s/article/KB-000036839

$InstallerLocation = ""
$InstallerArguments = ""

# Define Functions

function Get-SophosInstalled {

$Global:installed = (gp HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName -contains "Sophos Endpoint Agent"
$Global:mcsclient = Get-Service -name "Sophos MCS Client" -ea SilentlyContinue
$Global:mcsagent = Get-Service -name "Sophos MCS Agent" -ea SilentlyContinue
}

# Sophos Central Installation
Start-Transcript $env:systemdrive\temp\SophosCentralInstallLog.txt
Write-Host "Starting the Sophos Central Installation based on the variables defined in the site"
Write-Host ""
Write-Host "Checking to see if Sophos is Already Installed"

Get-SophosInstalled
if ($installed -eq "True") {
	Write-Host "--Sophos Central Endpoint Agent Installed"
	if ($mcsclient.Status -eq "Running"){	
	Write-Host "--Sophos MCS Client is Running"
	Exit 0
	}
}
else {
	Write-Host "--Sophos Central is Not Installed"
	Write-Host "Sophos MCS Client is Not Running"
	}

# Check if SophosSetup.exe Exists
Write-Host ""
Write-Host "Checking for SophosSetup.exe"

if (!(Test-Path $InstallerLocation -PathType leaf)) {
	Write-Host "--SophosSetup.exe Missing or Path is incorrect"
	Stop-Transcript
	Exit 1
	}
else {
	Write-Host "--InstallerLocation = "$InstallerLocation""
	Write-Host ""$InstallerArguments""
	}

# Check to see if a previous SophosSetup Process is running
Write-Host ""
Write-Host "Checking to see if SophosSetup.exe is already running"
if ((get-process "sophossetup" -ea SilentlyContinue) -eq $Null){
        Write-Host "--SophosSetup Not Running" 
}
else {
    Write-Host "Sophos Currently Running, Will Kill the Process before Continuing"
    Stop-Process -processname "sophossetup"
 }

# This Section starts the installer using the arguments defined above
Write-Host ""
Write-Host "Installing Sophos Central Endpoint:"
Write-Host ""
Write-Host "From: "$InstallerLocation""
Write-Host ""
Write-Host "With extra options: "$InstallerArguments""

if ($InstallerArguments -eq "") {
	start-process $InstallerLocation --quiet
}
else {
	start-process $InstallerLocation --quiet $InstallerArguments
}

$timeout = new-timespan -Minutes 30
$install = [diagnostics.stopwatch]::StartNew()
while ($install.elapsed -lt $timeout){
    if ((Get-Service "Sophos MCS Client" -ea SilentlyContinue)){
	Write-Host "Sophos MCS Client Found - Breaking the Loop"
	Break
	}
    start-sleep -seconds 60
}
Write-Host ""
Write-Host "Sophos Setup Completed"

# Verify that Sophos Central Endpoint Agent Installed
Write-Host ""
Write-Host "Verifying that Sophos Central Endpoint installed and is Running"

Get-SophosInstalled
if ($installed -eq "True") {
	Write-Host "--Sophos Central Endpoint Agent Installed Successfully"
	if ($mcsclient.Status -eq "Running"){
	Write-Host "--Sophos MCS Client is Running"
		if ($mcsagent.Status -eq "Running"){
		Write-Host "--Sophos MCS Agent is Running"
		Write-Host "Log Location - <system>\programdata\Sophos\Cloudinstaller\Logs\"
		Stop-Transcript
		Exit 0
		}
	}
}
else {
	Write-Host "--Sophos Central Install Failed"
	Write-Host ""
	Write-Host "Please check the Sophos Central Install Logs for more details"
	Write-Host ""
	Write-Host "Log Location - <system>\programdata\Sophos\Cloudinstaller\Logs\"
	Stop-Transcript
	Exit 1
	}
