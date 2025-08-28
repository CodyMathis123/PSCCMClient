#region PSCCMClient Module

# Get public and private function definition files
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)
$Classes = @(Get-ChildItem -Path $PSScriptRoot\Classes\*.ps1 -ErrorAction SilentlyContinue)
$Enums = @(Get-ChildItem -Path $PSScriptRoot\Enum\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files
foreach ($Import in @($Classes + $Enums + $Private + $Public)) {
    try {
        . $Import.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($Import.FullName): $_"
    }
}

# Export only the public functions
Export-ModuleMember -Function $Public.BaseName

#endregion PSCCMClient Module