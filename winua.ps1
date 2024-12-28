# ----------------------------------------------
# Windows Host Setup Script - Solvia Solution
# https://www.solvia.ch
# ----------------------------------------------

# Define a single log file path for the execution of the script
$ExecutionLogFile = "$Env:SystemDrive\Solvia\SolviaWinUA-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Print Welcome Message
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

# Function to Generate Secure Password
Function CreatePassword {
    param ([int]$passwordLength = 16)
    $specialChar = '$'
    $charsForPassword = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

    # Generate random alphanumeric characters for the middle part
    $randomChars = -join (1..($passwordLength - 2) | ForEach-Object { Get-Random -InputObject $charsForPassword.ToCharArray() })
    # Assemble password with special characters at both ends
    return $specialChar + $randomChars + $specialChar
}

# Function to Log to a File and Display with Write-Host
Function Log-Event {
    param (
        [string]$message,
        [string]$entryType = "Information"
    )
    # Ensure the directory exists
    if (-not (Test-Path -Path "$Env:SystemDrive\Solvia")) {
        New-Item -ItemType Directory -Path "$Env:SystemDrive\Solvia" | Out-Null
    }

    # Construct the log entry with timestamp and entry type
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$entryType] $message"

    # Write the log entry to the single execution-time log file
    Add-Content -Path $ExecutionLogFile -Value $logEntry

    # Display the log entry on the console
    Write-Host "$logEntry" -ForegroundColor Cyan
}

# Function to Download OfficeSetup
Function Download-OfficeSetup {
    try {
        $officeSetupPath = "$Env:SystemDrive\Solvia\OfficeSetup.exe"
        Invoke-WebRequest -Uri "https://sw-deploy.solvia.ch/OfficeSetup.exe" -OutFile $officeSetupPath -ErrorAction Stop
        Log-Event "OfficeSetup.exe downloaded to $officeSetupPath." "Information"
    } catch {
        Log-Event "Failed to download OfficeSetup.exe: $_" "Error"
        Exit 9
    }
}

# Initial Error Handling
Trap {
    Log-Event "Critical error: $_" "Error"
    Exit 1
}
$ErrorActionPreference = "Stop"

# Print Welcome
Print-Welcome

# Verify Administrator Privileges
try {
    $myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $myWindowsPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Administrator privileges are required. Run this script as Administrator."
    }
    Log-Event "Administrator privileges verified." "Information"
} catch {
    Write-Output $_.Exception.Message
    Exit 2
}

# Check PowerShell Version
try {
    if ($PSVersionTable.PSVersion.Major -lt 3) {
        throw "PowerShell version 3 or higher is required."
    }
    Log-Event "PowerShell version check passed." "Information"
} catch {
    Log-Event $_.Exception.Message "Error"
    Exit 3
}

# Set account properties for specified users
$users = @("ladmin", "luser", "solvia")
foreach ($user in $users) {
    try {
        Get-LocalUser $user | Set-LocalUser -PasswordNeverExpires $true
        Log-Event "Password expiration disabled for user $user." "Information"
    } catch {
        Log-Event "Failed to set password expiration for user $($user): $_" "Warning"
    }
}

# Create necessary folder
try {
    $solviaFolderPath = "$Env:SystemDrive\Solvia"
    if (-not (Test-Path -Path $solviaFolderPath)) {
        New-Item -ItemType Directory -Path $solviaFolderPath | Out-Null
        Log-Event "Folder $solviaFolderPath created." "Information"
    }
} catch {
    Log-Event "Failed to create folder $($solviaFolderPath): $_" "Error"
    Exit 4
}

# Download RustDesk and install it silently
try {
    $rustdeskInstaller = "$solviaFolderPath\rustdesk-1.3.5-x86_64.msi"
    Invoke-WebRequest -Uri "https://sw-deploy.solvia.ch/rustdesk-1.3.5-x86_64.msi" -OutFile $rustdeskInstaller -ErrorAction Stop
    Log-Event "RustDesk downloaded to $rustdeskInstaller." "Information"
    
    # Silent installation of RustDesk
    Start-Process -FilePath $rustdeskInstaller -ArgumentList "/quiet /norestart" -Wait
    Log-Event "RustDesk installed silently." "Information"
} catch {
    Log-Event "RustDesk download or installation failed: $_" "Error"
    Exit 5
}

# Generate and display password
try {
    $password = CreatePassword
    Write-Host "Please note this password: $password"
    Log-Event "Generated a secure password." "Information"
} catch {
    Log-Event "Failed to generate password: $_" "Error"
}

# Install Chocolatey
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Log-Event "Chocolatey installed." "Information"
} catch {
    Log-Event "Chocolatey installation failed: $_" "Error"
    Exit 6
}

# Download HPIA
try {
    Invoke-WebRequest -Uri "https://hpia.hpcloud.hp.com/downloads/hpia/hp-hpia-5.3.1.exe" -OutFile "$solviaFolderPath\hp-hpia-5.3.1.exe" -ErrorAction Stop
    Log-Event "HPIA downloaded and installed." "Information"
} catch {
    Log-Event "HPIA download or installation failed: $_" "Error"
    Exit 7
}

# Download Atera Agent and install it silently
try {
    $ateraInstaller = "$solviaFolderPath\atera-setup-unassigned.msi"
    Invoke-WebRequest -Uri "https://sw-deploy.solvia.ch/atera-setup-unassigned.msi" -OutFile $ateraInstaller -ErrorAction Stop
    Log-Event "Atera Agent downloaded to $ateraInstaller." "Information"
    # Silent installation of Atera Agent
    Start-Process -FilePath $ateraInstaller -ArgumentList "/quiet /norestart" -Wait
    Log-Event "Atera Agent installed silently." "Information"
} catch {
    Log-Event "Atera Agent installation failed: $_" "Error"
    Exit 8
}

# Download OfficeSetup
Download-OfficeSetup

# End of Script Prompt
Write-Host "Press any key to terminate the script"
$null = [Console]::ReadKey($true)
