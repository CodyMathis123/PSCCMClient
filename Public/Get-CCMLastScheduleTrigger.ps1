function Get-CCMLastScheduleTrigger {
    <#
    .SYNOPSIS
        Returns the last time a specified schedule was triggered
    .DESCRIPTION
        This function will return the last time a schedule was triggered. Keep in mind this is when a scheduled run happens, such as the periodic machine
        policy refresh. This is why you won't see the timestamp increment if you force a eval, and then check the schedule LastTriggerTime.
    .PARAMETER Schedule
        Specifies the schedule to get trigger history info for. This has a validate set of all possible 'standard' options that the client can perform
        on a schedule.
    .PARAMETER ScheduleID
        Specifies the ScheduleID to get trigger history info for. This is a non-validated parameter that lets you simply query for a ScheduleID of your choosing. 
    .PARAMETER CimSession
        Provides CimSessions to gather schedule trigger info from
    .PARAMETER ComputerName
        Provides computer names to gather schedule trigger info from
    .EXAMPLE
        C:\PS> Get-CCMLastScheduleTrigger -Schedule 'Hardware Inventory'
        Returns a [pscustomobject] detailing the schedule trigger history info available in WMI for Hardware Inventory
    .EXAMPLE
        C:\PS> Get-CCMLastScheduleTrigger -ComputerName 'Workstation1234','Workstation4321' -MWType 'Software Update Service Window'
            Return all the 'Software Update Service Window' Maintenance Windows for Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMLastScheduleTrigger.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2019-12-31
        Updated:     2020-01-05
    #>
    [CmdletBinding(DefaultParameterSetName = 'ComputerName')]
    param (
        [parameter(Mandatory = $true, ParameterSetName = 'ByName')]
        [parameter(ParameterSetName = 'CimSession')]
        [parameter(ParameterSetName = 'ComputerName')]
        [ValidateSet('Hardware Inventory',
            'Software Inventory',
            'Discovery Inventory',
            'File Collection',
            'IDMIF Collection',
            'Request Machine Assignments',
            'Evaluate Machine Policies',
            'Refresh Default MP Task',
            'LS (Location Service) Refresh Locations Task',
            'LS Timeout Refresh Task',
            'Policy Agent Request Assignment (User)',
            'Policy Agent Evaluate Assignment (User)',
            'Software Metering Generating Usage Report',
            'Source Update Message',
            'Clearing proxy settings cache',
            'Machine Policy Agent Cleanup',
            'User Policy Agent Cleanup',
            'Policy Agent Validate Machine Policy / Assignment',
            'Policy Agent Validate User Policy / Assignment',
            'Retrying/Refreshing certificates in AD on MP',
            'Peer DP Status reporting',
            'Peer DP Pending package check schedule',
            'SUM Updates install schedule',
            'Hardware Inventory Collection Cycle',
            'Software Inventory Collection Cycle',
            'Discovery Data Collection Cycle',
            'File Collection Cycle',
            'IDMIF Collection Cycle',
            'Software Metering Usage Report Cycle',
            'Windows Installer Source List Update Cycle',
            'Software Updates Policy Action Software Updates Assignments Evaluation Cycle',
            'PDP Maintenance Policy Branch Distribution Point Maintenance Task',
            'DCM policy',
            'Send Unsent State Message',
            'State System policy cache cleanout',
            'Update source policy',
            'Update Store Policy',
            'State system policy bulk send high',
            'State system policy bulk send low',
            'Application manager policy action',
            'Application manager user policy action',
            'Application manager global evaluation action',
            'Power management start summarizer',
            'Endpoint deployment reevaluate',
            'Endpoint AM policy reevaluate',
            'External event detection')]
        [string[]]$Schedule,
        [parameter(Mandatory = $true, ParameterSetName = 'ByID')]
        [parameter(ParameterSetName = 'CimSession')]
        [parameter(ParameterSetName = 'ComputerName')]
        [string[]]$ScheduleID,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CimSession')]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession,
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ComputerName')]
        [Alias('Connection', 'PSComputerName', 'PSConnectionName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:ComputerName
    )
    begin {
        #region hashtable for mapping schedule names to IDs, and create CIM query
        $ScheduleTypeMap = @{
            'Hardware Inventory'                                                           = '{00000000-0000-0000-0000-000000000001}'
            'Software Inventory'                                                           = '{00000000-0000-0000-0000-000000000002}'
            'Discovery Inventory'                                                          = '{00000000-0000-0000-0000-000000000003}'
            'File Collection'                                                              = '{00000000-0000-0000-0000-000000000010}'
            'IDMIF Collection'                                                             = '{00000000-0000-0000-0000-000000000011}'
            'Request Machine Assignments'                                                  = '{00000000-0000-0000-0000-000000000021}'
            'Evaluate Machine Policies'                                                    = '{00000000-0000-0000-0000-000000000022}'
            'Refresh Default MP Task'                                                      = '{00000000-0000-0000-0000-000000000023}'
            'LS (Location Service) Refresh Locations Task'                                 = '{00000000-0000-0000-0000-000000000024}'
            'LS Timeout Refresh Task'                                                      = '{00000000-0000-0000-0000-000000000025}'
            'Policy Agent Request Assignment (User)'                                       = '{00000000-0000-0000-0000-000000000026}'
            'Policy Agent Evaluate Assignment (User)'                                      = '{00000000-0000-0000-0000-000000000027}'
            'Software Metering Generating Usage Report'                                    = '{00000000-0000-0000-0000-000000000031}'
            'Source Update Message'                                                        = '{00000000-0000-0000-0000-000000000032}'
            'Clearing proxy settings cache'                                                = '{00000000-0000-0000-0000-000000000037}'
            'Machine Policy Agent Cleanup'                                                 = '{00000000-0000-0000-0000-000000000040}'
            'User Policy Agent Cleanup'                                                    = '{00000000-0000-0000-0000-000000000041}'
            'Policy Agent Validate Machine Policy / Assignment'                            = '{00000000-0000-0000-0000-000000000042}'
            'Policy Agent Validate User Policy / Assignment'                               = '{00000000-0000-0000-0000-000000000043}'
            'Retrying/Refreshing certificates in AD on MP'                                 = '{00000000-0000-0000-0000-000000000051}'
            'Peer DP Status reporting'                                                     = '{00000000-0000-0000-0000-000000000061}'
            'Peer DP Pending package check schedule'                                       = '{00000000-0000-0000-0000-000000000062}'
            'SUM Updates install schedule'                                                 = '{00000000-0000-0000-0000-000000000063}'
            'Hardware Inventory Collection Cycle'                                          = '{00000000-0000-0000-0000-000000000101}'
            'Software Inventory Collection Cycle'                                          = '{00000000-0000-0000-0000-000000000102}'
            'Discovery Data Collection Cycle'                                              = '{00000000-0000-0000-0000-000000000103}'
            'File Collection Cycle'                                                        = '{00000000-0000-0000-0000-000000000104}'
            'IDMIF Collection Cycle'                                                       = '{00000000-0000-0000-0000-000000000105}'
            'Software Metering Usage Report Cycle'                                         = '{00000000-0000-0000-0000-000000000106}'
            'Windows Installer Source List Update Cycle'                                   = '{00000000-0000-0000-0000-000000000107}'
            'Software Updates Policy Action Software Updates Assignments Evaluation Cycle' = '{00000000-0000-0000-0000-000000000108}'
            'PDP Maintenance Policy Branch Distribution Point Maintenance Task'            = '{00000000-0000-0000-0000-000000000109}'
            'DCM policy'                                                                   = '{00000000-0000-0000-0000-000000000110}'
            'Send Unsent State Message'                                                    = '{00000000-0000-0000-0000-000000000111}'
            'State System policy cache cleanout'                                           = '{00000000-0000-0000-0000-000000000112}'
            'Update source policy'                                                         = '{00000000-0000-0000-0000-000000000113}'
            'Update Store Policy'                                                          = '{00000000-0000-0000-0000-000000000114}'
            'State system policy bulk send high'                                           = '{00000000-0000-0000-0000-000000000115}'
            'State system policy bulk send low'                                            = '{00000000-0000-0000-0000-000000000116}'
            'Application manager policy action'                                            = '{00000000-0000-0000-0000-000000000121}'
            'Application manager user policy action'                                       = '{00000000-0000-0000-0000-000000000122}'
            'Application manager global evaluation action'                                 = '{00000000-0000-0000-0000-000000000123}'
            'Power management start summarizer'                                            = '{00000000-0000-0000-0000-000000000131}'
            'Endpoint deployment reevaluate'                                               = '{00000000-0000-0000-0000-000000000221}'
            'Endpoint AM policy reevaluate'                                                = '{00000000-0000-0000-0000-000000000222}'
            'External event detection'                                                     = '{00000000-0000-0000-0000-000000000223}'
        }
        $PSBoundParameters.Keys
        $RequestedSchedulesRaw = switch ($PSBoundParameters.Keys) {
            'Schedule' {
                foreach ($One in $Schedule) {
                    $ScheduleTypeMap[$One]
                }
            }
            'ScheduleID' {
                $ScheduleID
            }
        }
        $RequestedScheduleQuery = [string]::Format('SELECT * FROM CCM_Scheduler_History WHERE ScheduleID = "{0}"', [string]::Join('" OR ScheduleID = "', $RequestedSchedulesRaw))
        #endregion hashtable for mapping schedule names to IDs, and create CIM query

        $getSchedHistSplat = @{
            Namespace = 'root\CCM\Scheduler'
            Query     = $RequestedScheduleQuery
        }
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
                                $getSchedHistSplat.Remove('ComputerName')
                                $getSchedHistSplat['CimSession'] = $ExistingCimSession
                            }
                            else {
                                Write-Verbose "No active CimSession found for $Connection - falling back to -ComputerName parameter for CIM cmdlets"
                                $getSchedHistSplat.Remove('CimSession')
                                $getSchedHistSplat['ComputerName'] = $Connection
                            }
                        }
                        $true {
                            $getSchedHistSplat.Remove('CimSession')
                            $getSchedHistSplat.Remove('ComputerName')
                            Write-Verbose 'Local computer is being queried - skipping computername, and cimsession parameter'
                        }
                    }
                }
                'CimSession' {
                    Write-Verbose "Active CimSession found for $Connection - Passing CimSession to CIM cmdlets"
                    Write-Output -InputObject $Connection.ComputerName
                    $getSchedHistSplat.Remove('ComputerName')
                    $getSchedHistSplat['CimSession'] = $Connection
                }
            }
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer

            try {
                [ciminstance[]]$ScheduleHistory = Get-CimInstance @getSchedHistSplat
                if ($ScheduleHistory -is [Object] -and $ScheduleHistory.Count -gt 0) {
                    foreach ($Trigger in $ScheduleHistory) {
                        $Result['ScheduleID'] = $Trigger.ScheduleID
                        $Result['Schedule'] = $ScheduleTypeMap.Keys.Where( { $ScheduleTypeMap[$_] -eq $Trigger.ScheduleID } )
                        $Result['UserSID'] = $Trigger.UserSID
                        $Result['FirstEvalTime'] = $Trigger.FirstEvalTime
                        $Result['ActivationMessageSent'] = $Trigger.ActivationMessageSent
                        $Result['ActivationMessageSentIsGMT'] = $Trigger.ActivationMessageSentIsGMT
                        $Result['ExpirationMessageSent'] = $Trigger.ExpirationMessageSent
                        $Result['ExpirationMessageSentIsGMT'] = $Trigger.ExpirationMessageSentIsGMT
                        $Result['LastTriggerTime'] = $Trigger.LastTriggerTime
                        $Result['TriggerState'] = $Trigger.TriggerState
                        [PSCustomObject]$Result
                    }
                }
                else {
                    Write-Warning "No triggered schedules found for [Query = '$RequestedScheduleQuery']"
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Error $ErrorMessage
            }
        }
    }
}