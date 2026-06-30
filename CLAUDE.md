# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains Windows unattended setup scripts for Solvia Solution (https://www.solvia.ch). The main script (`winua.ps1`) automates Windows host configuration by installing software, configuring user accounts, and applying system settings.

## Running the Scripts

Both scripts require Administrator privileges and PowerShell 3+.

```powershell
# Run the main setup script (must be run as Administrator)
powershell -ExecutionPolicy Bypass -File winua.ps1

# Run directly from GitHub
irm https://raw.githubusercontent.com/itsChris/uasetup/main/winua.ps1 | iex

# Run the dummy/test script
powershell -ExecutionPolicy Bypass -File dummy-powershell.ps1
```

## Architecture

### winua.ps1 (Main Setup Script)
The script executes sequentially. Only critical failures cause exit; non-critical failures log a warning and continue:

**Critical (script exits):**
- **Exit 2**: Missing administrator privileges
- **Exit 3**: PowerShell version < 3
- **Exit 4**: Failed to create Solvia folder
- **Exit 5**: Atera Agent installation failure

**Non-critical (logs warning, continues):**
- RustDesk, Chocolatey, HPIA, WireGuard, OneDrive removal, OfficeSetup

### Key Functions
- `Log-Event`: Logs to `C:\Solvia\SolviaWinUA-<timestamp>.log` and console
- `CreatePassword`: Generates 16-char password with `$` delimiters
- `Download-OfficeSetup`: Downloads Office installers (EN and DE)
- `Print-Welcome`: Displays ASCII banner

### Software Installed (in order)
Downloads come from `https://sw-deploy.solvia.ch/` unless noted:
1. Atera Agent (RMM) - installed first for early visibility
2. RustDesk 1.4.8 (remote desktop)
3. Chocolatey (package manager) - from community.chocolatey.org
4. HP Image Assistant (HPIA) 5.3.6 - from hpia.hpcloud.hp.com
5. WireGuard 0.5.3 (VPN client) - downloaded only, not installed
6. Microsoft Office Setup (EN and DE) - downloaded only

### User Configuration
Disables password expiration for: `ladmin`, `luser`, `solvia`

### Registry Modifications
Removes OneDrive auto-start from default user profile (`NTUSER.DAT`)
