# TODO - Update help
function Get-CCMPackage {
    <#
    .SYNOPSIS
        Return deployed packages from a computer
    .DESCRIPTION
        Pulls a list of deployed packages from the specified computer(s) or CIMSession(s) with optional filters, and can be passed on
        to Invoke-CCMPackage if desired.

        Note that the parameters for filter are all joined together with OR.
    .PARAMETER PackageID
        An array of PackageID to filter on
    .PARAMETER PackageName
        An array of package names to filter on
    .PARAMETER ProgramName
        An array of program names to filter on
    .PARAMETER CimSession
        Provides CimSession to gather deployed package info from
    .PARAMETER ComputerName
        Provides computer names to gather deployed package info from
    .EXAMPLE
        PS> Get-CCMPackage
            Returns all deployed packages listed in WMI on the local computer
    .EXAMPLE
        PS> Get-CCMPackage -PackageName 'Software Install' -ProgramName 'Software Install - Silent'
            Returns all deployed packages listed in WMI on the local computer which have either a package name of 'Software Install' or
            a Program Name of 'Software Install - Silent'
    .NOTES
        FileName:    Get-CCMPackage.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-12
        Updated:     2020-02-19
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$PackageID,
        [Parameter(Mandatory = $false)]
        [string[]]$PackageName,
        [Parameter(Mandatory = $false)]
        [string[]]$ProgramName,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$ConnectionPreference
    )
    begin {
        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $getPackageSplat = @{
            NameSpace = 'root\CCM\Policy\Machine\ActualConfig'
        }
        #endregion define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
    }
    process {

        foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)) {
            $getConnectionInfoSplat = @{
                $PSCmdlet.ParameterSetName = $Connection
            }
            switch ($PSBoundParameters.ContainsKey('ConnectionPreference')) {
                $true {
                    $getConnectionInfoSplat['Prefer'] = $ConnectionPreference
                }
            }
            $ConnectionInfo = Get-CCMConnection @getConnectionInfoSplat
            $Computer = $ConnectionInfo.ComputerName
            $connectionSplat = $ConnectionInfo.connectionSplat
        
            try {
                $FilterParts = switch ($PSBoundParameters.Keys) {
                    'PackageID' {
                        [string]::Format('PKG_PackageID = "{0}"', [string]::Join('" OR PKG_PackageID = "', $PackageID))
                    }
                    'PackageName' {
                        [string]::Format('PKG_Name = "{0}"', [string]::Join('" OR PKG_Name = "', $PackageName))
                    }
                    'ProgramName' {
                        [string]::Format('PRG_ProgramName = "{0}"', [string]::Join('" OR PRG_ProgramName = "', $ProgramName))
                    }
                }
                $Filter = switch ($null -ne $FilterParts) {
                    $true {
                        [string]::Format(' WHERE {0}', [string]::Join(' OR ', $FilterParts))
                    }
                    $false {
                        ' '
                    }
                }
                $getPackageSplat['Query'] = [string]::Format('SELECT * FROM CCM_SoftwareDistribution{0}', $Filter)

                [ciminstance[]]$Packages = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getPackageSplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getPackageSplat @connectionSplat
                    }
                }
                if ($Packages -is [Object] -and $Packages.Count -gt 0) {
                    Write-Output -InputObject $Packages
                }
                else {
                    Write-Warning "No deployed package found for $Computer based on input filters"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
