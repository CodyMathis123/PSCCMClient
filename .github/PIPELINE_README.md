# Build Pipelines

This repository includes two separate GitHub Actions workflows for building and publishing packages:

## 🏗️ .NET Package Pipeline (`dotnet-package.yml`)

Builds and publishes the C# NuGet package for PSCCMClient.Core.

### Triggers
- **Push to main/master** - Builds when C# code changes (`src/**`, `PSCCMClient.sln`)
- **Release published** - Automatically publishes to NuGet.org
- **Manual dispatch** - Allows manual triggering with optional publishing

### Workflow Steps
1. **Build** - Restores dependencies, builds solution, runs tests
2. **Pack** - Creates NuGet package 
3. **Publish** - Publishes to NuGet.org (only on release or manual dispatch)

### Setup Requirements

#### Secrets
Add these secrets to your repository:
- `NUGET_API_KEY` - Your NuGet.org API key for publishing packages

#### Getting a NuGet API Key
1. Go to [nuget.org](https://www.nuget.org/)
2. Sign in and go to your account settings
3. Create a new API key with package push permissions
4. Add it as a repository secret named `NUGET_API_KEY`

---

## 📦 PowerShell Module Pipeline (`powershell-module.yml`)

Builds and publishes the PowerShell module to PowerShell Gallery.

### Triggers
- **Push to main/master** - Builds when PowerShell code changes (`Source/**`)
- **Release published** - Automatically publishes to PowerShell Gallery
- **Manual dispatch** - Allows manual triggering with optional publishing

### Workflow Steps
1. **Build** - Tests module manifest, runs PSScriptAnalyzer, Pester tests
2. **Package** - Creates module package
3. **Publish** - Publishes to PowerShell Gallery (only on release or manual dispatch)

### Setup Requirements

#### Secrets
Add these secrets to your repository:
- `POWERSHELL_GALLERY_API_KEY` - Your PowerShell Gallery API key

#### Getting a PowerShell Gallery API Key
1. Go to [PowerShell Gallery](https://www.powershellgallery.com/)
2. Sign in and go to account settings
3. Generate a new API key with push permissions
4. Add it as a repository secret named `POWERSHELL_GALLERY_API_KEY`

---

## 🚀 Manual Deployment

Both pipelines can be triggered manually from the Actions tab:

1. Go to **Actions** in your GitHub repository
2. Select the workflow you want to run
3. Click **Run workflow**
4. Choose whether to publish packages (optional)

---

## 📋 Pipeline Status

Both pipelines will show status badges and provide downloadable artifacts:

- **Build artifacts** - Always available for successful builds
- **Published packages** - Available on NuGet.org and PowerShell Gallery after publishing

### Example Usage After Publishing

#### .NET Package
```bash
dotnet add package PSCCMClient.Core
```

#### PowerShell Module
```powershell
Install-Module -Name PSCCMClient
```

---

## 🔧 Pipeline Configuration

### Customizing Triggers
Edit the `on:` section of each workflow to modify when they run.

### Adding Tests
- **C#**: Add test projects to the solution
- **PowerShell**: Add `.Tests.ps1` files for Pester to discover

### Version Management
- **C#**: Update version in `PSCCMClient.Core.csproj`
- **PowerShell**: Update `ModuleVersion` in `PSCCMClient.psd1`