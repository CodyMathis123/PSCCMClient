function Get-CCMApplication {
    <#
    .SYNOPSIS
        Return deployed applications from a computer
    .DESCRIPTION
        Pulls a list of deployed applications from the specified computer(s) or CIMSession(s) with optional filters, and can be passed on
        to Invoke-CCMApplication if desired.

        Note that the parameters for filter are all joined together with OR.
    .PARAMETER ApplicationName
        An array of ApplicationName to filter on
    .PARAMETER ApplicationID
        An array of application ID to filter on
    .PARAMETER CimSession
        Provides CimSession to gather deployed application info from
    .PARAMETER ComputerName
        Provides computer names to gather deployed application info from
    .EXAMPLE
        PS> Get-CCMApplication
            Returns all deployed applications listed in WMI on the local computer
    .EXAMPLE
        PS> Get-CCMApplication -ApplicationID ScopeId_BE389CA5-D6CC-42AF-B8F5-A059F9C9AD91/Application_0607d288-fc0b-42b7-9a61-76abedf0673e -ApplicationName 'Software Install - Silent'
            Returns all deployed applications listed in WMI on the local computer which have either a application name of 'Software Install' or
            a ID of 'ScopeId_BE389CA5-D6CC-42AF-B8F5-A059F9C9AD91/Application_0607d288-fc0b-42b7-9a61-76abedf0673e'
    .NOTES
        FileName:    Get-CCMApplication.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2020-01-21
        Updated:     2020-01-22
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$ApplicationName,
        [Parameter(Mandatory = $false)]
        [string[]]$ApplicationID,
        [Parameter(Mandatory = $false)]
        [string[]]$ProgramName,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        $connectionSplat = @{ }
        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $getapplicationsplat = @{
            NameSpace = 'root\CCM\ClientSDK'
            ClassName = 'CCM_Application'
        }
        #endregion define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
    }
    process {
        foreach ($Connection in (Get-Variable -Name $PSCmdlet.ParameterSetName -ValueOnly)) {
            $Computer = switch ($PSCmdlet.ParameterSetName) {
                'ComputerName' {
                    Write-Output -InputObject $Connection
                    switch ($Connection -eq $env:ComputerName) {
                        $false {
                            if ($ExistingCimSession = Get-CimSession -ComputerName $Connection -ErrorAction Ignore) {
                                Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                                $connectionSplat.Remove('ComputerName')
                                $connectionSplat['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
                                $connectionSplat.Remove('CimSession')
                                $connectionSplat['ComputerName'] = $Connection
                            }
                        }
                        $true {
                            $connectionSplat.Remove('CimSession')
                            $connectionSplat.Remove('ComputerName')
                            Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
                        }
                    }
                }
                'CimSession' {
                    Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                    Write-Output -InputObject $Connection.ComputerName
                    $connectionSplat.Remove('ComputerName')
                    $connectionSplat['CimSession'] = $Connection
                }
            }

            try {
                <#
                    AllowedActions             Property   string[] AllowedActions {get;set;}
                    AppDTs                     Property   CimInstance#InstanceArray AppDTs {get;set;}
                    ApplicabilityState         Property   string ApplicabilityState {get;set;}
                    ConfigureState             Property   string ConfigureState {get;set;}
                    ContentSize                Property   uint32 ContentSize {get;set;}
                    Deadline                   Property   CimInstance#DateTime Deadline {get;set;}
                    DeploymentReport           Property   string DeploymentReport {get;set;}
                    Description                Property   string Description {get;set;}
                    EnforcePreference          Property   uint32 EnforcePreference {get;set;}
                    ErrorCode                  Property   uint32 ErrorCode {get;set;}
                    EstimatedInstallTime       Property   uint32 EstimatedInstallTime {get;set;}
                    EvaluationState            Property   uint32 EvaluationState {get;set;}
                    FileTypes                  Property   string FileTypes {get;set;}
                    FullName                   Property   string FullName {get;set;}
                    HighImpactDeployment       Property   bool HighImpactDeployment {get;set;}
                    Icon                       Property   string Icon {get;set;}
                    Id                         Property   string Id {get;set;}
                    InformativeUrl             Property   string InformativeUrl {get;set;}
                    InProgressActions          Property   string[] InProgressActions {get;set;}
                    InstallState               Property   string InstallState {get;set;}
                    IsMachineTarget            Property   bool IsMachineTarget {get;set;}
                    IsPreflightOnly            Property   bool IsPreflightOnly {get;set;}
                    LastEvalTime               Property   CimInstance#DateTime LastEvalTime {get;set;}
                    LastInstallTime            Property   CimInstance#DateTime LastInstallTime {get;set;}
                    Name                       Property   string Name {get;set;}
                    NextUserScheduledTime      Property   CimInstance#DateTime NextUserScheduledTime {get;set;}
                    NotifyUser                 Property   bool NotifyUser {get;set;}
                    OverrideServiceWindow      Property   bool OverrideServiceWindow {get;set;}
                    PercentComplete            Property   uint32 PercentComplete {get;set;}
                    PSComputerName             Property   string PSComputerName {get;}
                    Publisher                  Property   string Publisher {get;set;}
                    RebootOutsideServiceWindow Property   bool RebootOutsideServiceWindow {get;set;}
                    ReleaseDate                Property   CimInstance#DateTime ReleaseDate {get;set;}
                    ResolvedState              Property   string ResolvedState {get;set;}
                    Revision                   Property   string Revision {get;set;}
                    SoftwareVersion            Property   string SoftwareVersion {get;set;}
                    StartTime                  Property   CimInstance#DateTime StartTime {get;set;}
                    SupersessionState          Property   string SupersessionState {get;set;}
                    Type                       Property   uint32 Type {get;set;}
                    UserUIExperience           Property   bool UserUIExperience {get;set;}
                #>
                $FilterParts = switch ($PSBoundParameters.Keys) {
                    'ApplicationName' {
                        [string]::Format('$AppFound.Name -eq "{0}"', [string]::Join('" -or $AppFound.Name -eq "', $ApplicationName))
                    }
                    'ApplicationID' {
                        [string]::Format('$AppFound.ID -eq "{0}"', [string]::Join('" -or $AppFound.ID -eq "', $ApplicationID))
                    }
                }
                [ciminstance[]]$applications = Get-CimInstance @getapplicationsplat @connectionSplat
                if ($applications -is [Object] -and $applications.Count -gt 0) {
                    #region Filterering is not possible on the CCM_Application class, so instead we loop and compare properties to filter
                    $Condition = switch ($FilterParts -is [string[]]) {
                        $true {
                            [scriptblock]::Create([string]::Join(' -or ', $FilterParts))
                        }
                    }
                    foreach ($AppFound in $applications) {
                        switch ($null -ne $Condition) {
                            $true {
                                switch (. $Condition) {
                                    $true {
                                        $AppFound
                                    }
                                }
                            }
                            $false {
                                $AppFound
                            }
                        }
                    }
                    #endregion Filterering is not possible on the CCM_Application class, so instead we loop and compare properties to filter

                    # ENHANCE - Select relevant properties and order them
                }
                else {
                    Write-Warning "No deployed applications found for $Computer based on input filters"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}
