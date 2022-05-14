function Get-CCMApplication {
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$ApplicationName,
        [Parameter(Mandatory = $false)]
        [string[]]$ApplicationID,
        [Parameter(Mandatory = $false)]
        [switch]$IncludeIcon,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName,
        [Parameter(Mandatory = $false, ParameterSetName = 'PSSession')]
        [Alias('Session')]      
        [System.Management.Automation.Runspaces.PSSession[]]$PSSession,
        [Parameter(Mandatory = $false, ParameterSetName = 'ComputerName')]
        [ValidateSet('CimSession', 'PSSession')]
        [string]$ConnectionPreference
    )
    # ENHANCE - Support lazy loading properties
    begin {
        #region define our hash tables for parameters to pass to Get-CIMInstance and our return hash table
        $getapplicationsplat = @{
            NameSpace = 'root\CCM\ClientSDK'
            ClassName = 'CCM_Application'
        }
        #endregion define our hash tables for parameters to pass to Get-CIMInstance and our return hash table

        #region EvaluationState hashtable for mapping
        $evaluationStateMap = @{
            0  = 'No state information is available.'
            1  = 'Application is enforced to desired/resolved state.'
            2  = 'Application is not required on the client.'
            3  = 'Application is available for enforcement (install or uninstall based on resolved state). Content may/may not have been downloaded.'
            4  = 'Application last failed to enforce (install/uninstall).'
            5  = 'Application is currently waiting for content download to complete.'
            6  = 'Application is currently waiting for content download to complete.'
            7  = 'Application is currently waiting for its dependencies to download.'
            8  = 'Application is currently waiting for a service (maintenance) window.'
            9  = 'Application is currently waiting for a previously pending reboot.'
            10 =	'Application is currently waiting for serialized enforcement.'
            11 =	'Application is currently enforcing dependencies.'
            12 =	'Application is currently enforcing.'
            13 =	'Application install/uninstall enforced and soft reboot is pending.'
            14 =	'Application installed/uninstalled and hard reboot is pending.'
            15 =	'Update is available but pending installation.'
            16 =	'Application failed to evaluate.'
            17 =	'Application is currently waiting for an active user session to enforce.'
            18 =	'Application is currently waiting for all users to logoff.'
            19 =	'Application is currently waiting for a user logon.'
            20 =	'Application in progress, waiting for retry.'
            21 =	'Application is waiting for presentation mode to be switched off.'
            22 =	'Application is pre-downloading content (downloading outside of install job).'
            23 =	'Application is pre-downloading dependent content (downloading outside of install job).'
            24 =	'Application download failed (downloading during install job).'
            25 =	'Application pre-downloading failed (downloading outside of install job).'
            26 =	'Download success (downloading during install job).'
            27 =	'Post-enforce evaluation.'
            28 =	'Waiting for network connectivity.'
        }
        #endregion EvaluationState hashtable for mapping
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

            $Return = [ordered]@{ }
            $Return['ComputerName'] = $Computer

            try {
                $FilterParts = switch ($PSBoundParameters.Keys) {
                    'ApplicationName' {
                        [string]::Format('$AppFound.Name -eq "{0}"', [string]::Join('" -or $AppFound.Name -eq "', $ApplicationName))
                    }
                    'ApplicationID' {
                        [string]::Format('$AppFound.ID -eq "{0}"', [string]::Join('" -or $AppFound.ID -eq "', $ApplicationID))
                    }
                }
                [array]$applications = switch ($Computer -eq $env:ComputerName) {
                    $true {
                        Get-CimInstance @getapplicationsplat @connectionSplat
                    }
                    $false {
                        Get-CCMCimInstance @getapplicationsplat @connectionSplat
                    }
                }
                if ($applications -is [Object] -and $applications.Count -gt 0) {
                    #region Filterering is not possible on the CCM_Application class, so instead we loop and compare properties to filter
                    $Condition = switch ($null -ne $FilterParts) {
                        $true {
                            [scriptblock]::Create([string]::Join(' -or ', $FilterParts))
                        }
                    }
                    foreach ($AppFound in $applications) {
                        $AppToReturn = switch ($null -ne $Condition) {
                            $true {
                                switch ($Condition.Invoke()) {
                                    $true {
                                        $AppFound
                                    }
                                }
                            }
                            $false {
                                $AppFound
                            }
                        }
                        switch ($null -ne $AppToReturn) {
                            $true {
                                $PropsToShow = 'Name', 'FullName', 'SoftwareVersion', 'Publisher', 'Description',
                                'Id', 'Revision', 'EvaluationState', 'ErrorCode', 'AllowedActions', 'ResolvedState',
                                'InstallState', 'ApplicabilityState', 'ConfigureState', 'LastEvalTime', 'LastInstallTime',
                                'StartTime', 'Deadline', 'NextUserScheduledTime', 'IsMachineTarget', 'IsPreflightOnly',
                                'NotifyUser', 'UserUIExperience', 'OverrideServiceWindow', 'RebootOutsideServiceWindow',
                                'AppDTs', 'ContentSize', 'DeploymentReport', 'EnforcePreference', 'EstimatedInstallTime',
                                'FileTypes', 'HighImpactDeployment', 'InformativeUrl', 'InProgressActions', 'PercentComplete',
                                'ReleaseDate', 'SupersessionState', 'Type'
                                foreach ($PropertyName in $PropsToShow) {
                                    $Return[$PropertyName] = $AppToReturn.$PropertyName
                                }

                                switch ($IncludeIcon.IsPresent) {
                                    $true {
                                        $Return['Icon'] = $AppToReturn.Icon
                                    }
                                }
                                [pscustomobject]$Return
                            }
                        }
                    }
                    #endregion Filterering is not possible on the CCM_Application class, so instead we loop and compare properties to filter
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
