# Windows Laptop Setup Guide
**Git · Azure CLI · Visual Studio Code · Azure & Bicep · GitHub**

This guide walks you through setting up a **Windows laptop** for Azure Infrastructure-as-Code development using **Git**, **Azure CLI**, **Visual Studio Code**, and **Bicep**.

---

## 1) Install Git (Windows)

1. Download **Git for Windows**:  
   https://git-scm.com/download/win
2. Run the installer and keep the default options.
   - Ensure **“Git from the command line and also from 3rd-party software”** is selected.
   - You may choose **Visual Studio Code** as the default editor if prompted.
3. Open **PowerShell** and verify:
   ```powershell
   git --version
   ```

---

## 2) Install Azure CLI (`az`)

### Option A (Recommended): Winget
1. Open **PowerShell**
2. Run:
   ```powershell
   winget install -e --id Microsoft.AzureCLI
   ```
3. Close and reopen PowerShell, then verify:
   ```powershell
   az version
   ```

### Option B: MSI Installer
- Download from: https://aka.ms/installazurecliwindows
- Install and then verify with:
  ```powershell
  az version
  ```

> If VS Code was open during installation, close and reopen it so PATH updates are picked up.

---

## 3) Install Visual Studio Code

1. Download from:  
   https://code.visualstudio.com/
2. Run the installer.
   - (Optional) Enable **Add to PATH**
3. Launch **Visual Studio Code**

---

## 4) Install Azure & Bicep Extensions in VS Code

1. Open VS Code
2. Open Extensions (`Ctrl + Shift + X`)
3. Install:

### Required
- **Bicep** (Microsoft)
- **Azure Account** (Microsoft)

### Recommended
- **Azure Resource Manager (ARM) Tools**
- **Azure CLI Tools**
- **Azure App Service**

Restart VS Code if prompted.

---

## 5) Sign in to Azure from VS Code

1. Press `Ctrl + Shift + P`
2. Run **Azure: Sign In**
3. Complete the browser login
4. Confirm your subscription appears in the Azure sidebar

---

## 6) Configure Git (One-Time)

Open **PowerShell**:
```powershell
git config --global user.name "Your Name"
git config --global user.email "you@company.com"
```

Verify:
```powershell
git config --global --list
```

---

## 7) Clone a GitHub Repository into VS Code

### Option A: VS Code UI
1. Press `Ctrl + Shift + P`
2. Run **Git: Clone**
3. Paste the repository URL:
   ```
   https://github.com/sapience-open/iac.git
   ```
4. Choose a local folder
5. Click **Open** when prompted

### Option B: PowerShell
```powershell
cd $HOME\Documents
git clone https://github.com/sapience-open/iac.git
cd iac
code .
```

---

## 8) Verify Everything Works

### Git
```powershell
git status
```

### Azure CLI
```powershell
az login
az account show
```

### Bicep Linting
- Open a `.bicep` file
- Lint warnings appear as yellow squiggles
- View all issues with `Ctrl + Shift + M`

Optional CLI lint:
```powershell
az bicep lint --file Ntier/infra.bicep
```

---

## 9) Common Windows Issues

- **`git` or `az` not found**  
  Reopen PowerShell and VS Code.
- **Command Prompt issues**  
  Prefer **PowerShell** or **Git Bash**.
- **Case sensitivity**  
  `Ntier` and `ntier` are different on GitHub runners.

---

## Next Steps
- Configure GitHub authentication (HTTPS or SSH)
- Set up GitHub Actions with Azure OIDC
- Run your first Bicep deployment
