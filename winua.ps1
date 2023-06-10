#Requires -Version 3.0

# Configure a Windows host
# ------------------------
#
# This script is used to finalize the setup of a Windows computer
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class MessageBox {
[DllImport("user32.dll", CharSet = CharSet.Auto)]
public static extern uint MessageBox(IntPtr hWnd, String text, String caption, uint type);
}
"@
# Function to check for internet connection
function Test-InternetConnection {
    param(
        $URL = "http://www.google.com"
    )
    try {
        $request = [net.WebRequest]::Create($URL)
        $request.Method = "GET"
        $response = $request.GetResponse()
        return $true
    }
    catch {
        return $false
    }
}

# Setup error handling.
Trap {
    $_
    Exit 1
}
$ErrorActionPreference = "Stop"

Write-Host "Hi!"

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

New-Item -ItemType Directory -Path $Env:SystemDrive\Solvia

# Continuously check for internet connection until there is one
while (!(Test-InternetConnection)) {
    [void] [MessageBox]::MessageBox(0, "Please connect the computer to the internet (maybe a driver is missing..)", "No internet connection", 0)
    Start-Sleep -Seconds 5
}

Invoke-WebRequest -Uri "https://download.anydesk.com/AnyDesk.exe" -OutFile $Env:SystemDrive\Solvia\AnyDesk.exe
Start-Process -FilePath "C:\Solvia\AnyDesk.exe"



