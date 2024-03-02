# Configure a Windows host
# ------------------------
#
# This script is used to finalize the setup of a Windows computer
# _______  _______  _                _________ _______ 
#(  ____ \(  ___  )( \      |\     /|\__   __/(  ___  )
#| (    \/| (   ) || (      | )   ( |   ) (   | (   ) |
#| (_____ | |   | || |      | |   | |   | |   | (___) |
#(_____  )| |   | || |      ( (   ) )   | |   |  ___  |
#      ) || |   | || |       \ \_/ /    | |   | (   ) |
#/\____) || (___) || (____/\  \   /  ___) (___| )   ( |
#\_______)(_______)(_______/   \_/   \_______/|/     \|
#
#Solution by Solvia
#https://www.solvia.ch
#info@solvia.ch
#---------------------------

Function Print-Welcome {
    Write-Host "
     _______  _______  _                _________ _______ 
    (  ____ \(  ___  )( \      |\     /|\__   __/(  ___  )
    | (    \/| (   ) || (      | )   ( |   ) (   | (   ) |
    | (_____ | |   | || |      | |   | |   | |   | (___) |
    (_____  )| |   | || |      ( (   ) )   | |   |  ___  |
          ) || |   | || |       \ \_/ /    | |   | (   ) |
    /\____) || (___) || (____/\  \   /  ___) (___| )   ( |
    \_______)(_______)(_______/   \_/   \_______/|/     \|

    Solution by Solvia
    https://www.solvia.ch
    info@solvia.ch" -ForegroundColor Cyan

}
# Setup error handling.
Trap {
    $_
    Exit 1
}
$ErrorActionPreference = "Stop"
# Print Welcome
Print-Welcome

# Get the ID and security principal of the current user account
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)

# Get the security principal for the Administrator role
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

# Check to see if we are currently running "as Administrator"
if (-Not $myWindowsPrincipal.IsInRole($adminRole)) {
    Write-Output "ERROR: You need elevated Administrator privileges in order to run this script."
    Write-Output "       Start Windows PowerShell by using the Run as Administrator option."
    Exit 2
}

$EventSource = $MyInvocation.MyCommand.Name
If (-Not $EventSource) {
    $EventSource = "Powershell CLI"
}

If ([System.Diagnostics.EventLog]::Exists('Application') -eq $False -or [System.Diagnostics.EventLog]::SourceExists($EventSource) -eq $False) {
    New-EventLog -LogName Application -Source $EventSource
}

# Detect PowerShell version.
If ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-ProgressLog "PowerShell version 3 or higher is required."
    Throw "PowerShell version 3 or higher is required."
}

# Set account properties
Get-LocalUser ladmin | Set-LocalUser -PasswordNeverExpires
Get-LocalUser luser | Set-LocalUser -PasswordNeverExpires
Get-LocalUser solvia | Set-LocalUser -PasswordNeverExpires

# Create folders
New-Item -ItemType Directory -Path $Env:SystemDrive\Solvia

# Download and start AnyDesk
Invoke-WebRequest -Uri "https://files.solvia.ch/AnyDesk_Custom_Client-Solvia.exe" -OutFile $Env:SystemDrive\Solvia\AnyDesk.exe
Infoke-WebReqeust -Uri "https://download.anydesk.com/AnyDesk.exe" -OutFile $Env:SystemDrive\Solvia\AnyDeskFull.exe

Start-Process -FilePath "C:\Solvia\AnyDesk.exe"

# Start a shell (will run as system account!)
Start-Process PowerShell

Write-Host "Press any key to terminate the script"
$null = [Console]::ReadKey($true)
