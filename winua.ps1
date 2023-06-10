#Requires -Version 3.0

# Configure a Windows host
# ------------------------
#
# This script is used to finalize the setup of a Windows computer

# Get the ID and security principal of the current user account
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

# Get the security principal for the Administrator role
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

# Check to see if we are currently running "as Administrator"
if (-Not $myWindowsPrincipal.IsInRole($adminRole)) {
    Write-Output "ERROR: You need elevated Administrator privileges in order to run this script."
    Write-Output "       Start Windows PowerShell by using the Run as Administrator option."
    Exit 2
}
