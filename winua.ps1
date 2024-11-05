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

Function CreatePassword {
    $passwordLength = 16
    $specialChar = '$'
    $charsForPassword = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    
    # Generate random alphanumeric characters for the middle part
    $randomChars = -join (1..($passwordLength - 2) | ForEach-Object { Get-Random -InputObject $charsForPassword.ToCharArray() })
    
    # Assemble the password with $ at the beginning and end
    $password = $specialChar + $randomChars + $specialChar

    return $password
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
Get-LocalUser ladmin | Set-LocalUser -PasswordNeverExpires $true
Get-LocalUser luser | Set-LocalUser -PasswordNeverExpires $true
Get-LocalUser solvia | Set-LocalUser -PasswordNeverExpires $true

# Create folders
if (-not (Test-Path -Path "$Env:SystemDrive\Solvia")) {
    New-Item -ItemType Directory -Path "$Env:SystemDrive\Solvia"
}

# Download and start AnyDesk
Invoke-WebRequest -Uri "https://files.solvia.ch/AnyDesk_Custom_Client-Solvia.exe" -OutFile $Env:SystemDrive\Solvia\AnyDesk.exe
Invoke-WebRequest -Uri "https://download.anydesk.com/AnyDesk.exe" -OutFile $Env:SystemDrive\Solvia\AnyDeskFull.exe
Invoke-WebRequest -Uri "https://sw-deploy.solvia.ch/rustdesk-1.3.2-x86_64.msi" -OutFile $Env:SystemDrive\Solvia\rustdesk-1.3.2-x86_64.msi

Start-Process -FilePath "C:\Solvia\AnyDeskFull.exe" -ArgumentList "--install '$env:ProgramFiles(x86)\AnyDesk' --start-with-win --silent --create-shortcuts --create-desktop-icon" -Wait
$password = CreatePassword 

$password = Start-Process -FilePath "C:\Install\AnyDesk\Here\AnyDesk.exe" -ArgumentList "--set-password" -Wait -NoNewWindow -RedirectStandardInput

Write-Host "Please note this password: $password"

### Install Chocolatey ###

# Bypass the execution policy for this process
Set-ExecutionPolicy Bypass -Scope Process -Force

# Ensure TLS 1.2 is available for secure web requests
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

# Download and execute the Chocolatey install script
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Download OneDriveKiller (UnDrive)
Invoke-WebRequest -Uri "https://files.solvia.ch/OneDriveKiller/SolviaOneDriveKiller.zip" -OutFile $Env:SystemDrive\Solvia\SolviaOneDriveKiller.zip
Expand-Archive -Path "$Env:SystemDrive\Solvia\SolviaOneDriveKiller.zip" -DestinationPath "$Env:SystemDrive\Solvia"

# Start a shell
Start-Process PowerShell

Write-Host "Press any key to terminate the script"
$null = [Console]::ReadKey($true)
