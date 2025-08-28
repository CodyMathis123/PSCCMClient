# Build Pipelines

This repository includes two separate GitHub Actions workflows for building packages and creating GitHub releases with assets:

## 🏗️ .NET Package Pipeline (`dotnet-package.yml`)

Builds the C# NuGet package for PSCCMClient.Core and can create GitHub releases with package assets.

### Triggers
- **Push to branches** - Builds when C# code changes (`src/**`, `PSCCMClient.sln`)
  - `main`, `master`, `feature/github-assets-publishing`
- **Manual dispatch** - Allows manual triggering with option to create GitHub release

### Workflow Steps
1. **Build** - Restores dependencies, builds solution, runs tests
2. **Pack** - Creates NuGet package with version detection
3. **Upload Artifacts** - Always uploads build artifacts
4. **Create Release** - (Manual only) Creates GitHub release with NuGet package asset

### Manual Release Creation
1. Go to **Actions** → **Build and Package .NET Library**
2. Click **Run workflow**
3. Check **"Create GitHub release with assets"**
4. Optionally specify a **release tag** (e.g., `v1.2.0`)
5. Run the workflow

---

## 📦 PowerShell Module Pipeline (`powershell-module.yml`)

Builds the PowerShell module and can create GitHub releases with module assets.

### Triggers
- **Push to branches** - Builds when PowerShell code changes (`Source/**`)
  - `main`, `master`, `feature/github-assets-publishing`
- **Manual dispatch** - Allows manual triggering with option to create GitHub release

### Workflow Steps
1. **Build** - Tests module manifest, runs PSScriptAnalyzer, Pester tests
2. **Package** - Creates versioned module zip package
3. **Upload Artifacts** - Always uploads build artifacts
4. **Create Release** - (Manual only) Creates GitHub release with module zip asset

### Manual Release Creation
1. Go to **Actions** → **Build and Package PowerShell Module**
2. Click **Run workflow**
3. Check **"Create GitHub release with assets"**
4. Optionally specify a **release tag** (e.g., `v1.2.0`)
5. Run the workflow

---

## 🎯 Usage After Release

### Installing from GitHub Releases

#### .NET Package
```bash
# Download .nupkg from GitHub releases
# Install locally:
dotnet add package PSCCMClient.Core --source ./path/to/downloaded/package
```

#### PowerShell Module
```powershell
# Download zip from GitHub releases
# Extract and import:
Expand-Archive -Path "PSCCMClient-1.0.0.zip" -DestinationPath "C:\Modules\"
Import-Module "C:\Modules\PSCCMClient\PSCCMClient.psd1"
```

---

## 🔧 Pipeline Configuration

### Branch Protection
Both workflows currently build on:
- `main`
- `master` 
- `feature/github-assets-publishing` (for testing)

### Version Detection
- **C#**: Automatically reads version from `PSCCMClient.Core.csproj`
- **PowerShell**: Automatically reads version from `PSCCMClient.psd1`
- **Fallback**: Uses `1.0.0` if version not found

### Release Naming
- **Default tags**: `dotnet-v{version}` or `powershell-v{version}`
- **Custom tags**: Can be specified during manual dispatch
- **Release names**: Include package type and version information

### Artifacts
Both workflows always upload build artifacts, even without creating releases:
- Artifacts include version numbers in names
- Available for download from the Actions tab
- Retained according to repository retention settings

---

## 🚀 Future Migration

When ready to publish to external repositories:

1. **Add secrets** for external publishing:
   - `NUGET_API_KEY` - For NuGet.org
   - `POWERSHELL_GALLERY_API_KEY` - For PowerShell Gallery

2. **Modify workflows** to add external publishing steps

3. **Update triggers** to publish automatically on main/master releases

This approach allows testing the build process and GitHub releases before committing to external package publication.