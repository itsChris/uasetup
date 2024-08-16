# Set folder path
$folderPath = "$env:SystemDrive\Solvia"

# Check if the folder exists, create if it doesn't
if (-not (Test-Path -Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory
    Write-Output "Folder 'Solvia' created at $folderPath"
} else {
    Write-Output "Folder 'Solvia' already exists at $folderPath"
}

# Generate the log file name with date-time stamp
$dateTime = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$logFileName = "$dateTime.log"
$logFilePath = Join-Path -Path $folderPath -ChildPath $logFileName

# Get current username and computer name
$username = $env:USERNAME
$computerName = $env:COMPUTERNAME

# Write username and computer name to the log file
"Username: $username" | Out-File -FilePath $logFilePath -Append
"Computer Name: $computerName" | Out-File -FilePath $logFilePath -Append

Write-Output "Log file '$logFileName' created at $folderPath with user and computer details."
