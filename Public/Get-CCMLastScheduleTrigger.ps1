function Get-CCMLastScheduleTrigger {
    <#
    .SYNOPSIS
        Returns the last time hardware inventory was ran
    .DESCRIPTION
        This function will return the last time a hardware inventory scan was triggered. You can provide an array of computer names, or you can pass 
        them through the pipeline.
    .PARAMETER ComputerName
        Provides computer names to gather MW info from.
    .PARAMETER MWType
        Specifies the types of MW you want information for. Valid options are below
            'All Deployment Service Window',
            'Program Service Window',
            'Reboot Required Service Window',
            'Software Update Service Window',
            'Task Sequences Service Window',
            'Corresponds to non-working hours'
    .PARAMETER Credential
        Provides optional credentials to use for the WMI cmdlets.
    .EXAMPLE
        C:\PS> Get-CCMLastScheduleTrigger
            Return all the 'All Deployment Service Window', 'Software Update Service Window' Maintenance Windows for the local computer. These are the two default MW types
            that the function looks for
    .EXAMPLE
        C:\PS> Get-CCMLastScheduleTrigger -ComputerName 'Workstation1234','Workstation4321' -MWType 'Software Update Service Window'
            Return all the 'Software Update Service Window' Maintenance Windows for Workstation1234, and Workstation4321
    .NOTES
        FileName:    Get-CCMLastScheduleTrigger.ps1
        Author:      Cody Mathis
        Contact:     @CodyMathis123
        Created:     2019-12-31
        Updated:     2019-12-31
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName)]
        [Alias('Computer', 'PSComputerName', 'IPAddress', 'ServerName', 'HostName', 'DNSHostName')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [parameter(Mandatory = $true, ParameterSetName = 'ByName')]
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
        [string[]]$ScheduleID,
        [parameter(Mandatory = $false)]
        [pscredential]$Credential
    )
    begin {
        #region hashtable for mapping schedule names to IDs, and create WMI query
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
        $RequestedSchedulesRaw = foreach ($One in $Schedule) {
            $ScheduleTypeMap[$One]
        }
        $RequestedScheduleQuery = [string]::Format('SELECT * FROM CCM_Scheduler_History WHERE ScheduleID = "{0}"', [string]::Join('" OR ScheduleID = "', $RequestedSchedulesRaw))
        #endregion hashtable for mapping schedule names to IDs, and create WMI query

        $getWmiObjectHINV = @{
            Namespace = 'root\CCM\Scheduler'
            Query     = $RequestedScheduleQuery
        }
        if ($PSBoundParameters.ContainsKey('Credential')) {
            $getWmiObjectHINV['Credential'] = $Credential
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            $Result = [System.Collections.Specialized.OrderedDictionary]::new()
            $Result['ComputerName'] = $Computer
            $getWmiObjectHINV['ComputerName'] = $Computer

            try {
                [System.Management.ManagementObject[]]$ScheduleHistory = Get-WmiObject @getWmiObjectHINV
                if ($ScheduleHistory -is [Object] -and $ScheduleHistory.Count -gt 0) {
                    foreach ($Trigger in $ScheduleHistory) {
                        <#
                            String  ScheduleID;  
                            String  UserSID;  
                            DateTime  FirstEvalTime;  
                            DateTime  ActivationMessageSent;  
                            Boolean  ActivationMessageSentIsGMT;  
                            DateTime  ExpirationMessageSent;  
                            Boolean  ExpirationMessageSentIsGMT;     
                            DateTime  LastTriggerTime;  
                            String  TriggerState; 
                        #>
                        $Result['ScheduleID'] = $Trigger.ScheduleID
                        $Result['Schedule'] = $ScheduleTypeMap.Keys.Where( { $ScheduleTypeMap[$_] -eq $Trigger.ScheduleID } )
                        $Result['UserSID'] = $Trigger.UserSID
                        $Result['FirstEvalTime'] = switch($Trigger.FirstEvalTime) {
                            $null {
                                continue
                            }
                            default {
                                [DateTime]::ParseExact(($PSItem.Split('+|-')[0]), 'yyyyMMddHHmmss.ffffff', [System.Globalization.CultureInfo]::InvariantCulture)
                            }
                        } 
                        $Result['ActivationMessageSent'] = switch($Trigger.ActivationMessageSent) {
                            $null {
                                continue
                            }
                            default {
                                [DateTime]::ParseExact(($PSItem.Split('+|-')[0]), 'yyyyMMddHHmmss.ffffff', [System.Globalization.CultureInfo]::InvariantCulture)
                            }
                        } 
                        $Result['ActivationMessageSentIsGMT'] = $Trigger.ActivationMessageSentIsGMT
                        $Result['ExpirationMessageSent'] = switch($Trigger.ExpirationMessageSent) {
                            $null {
                                continue
                            }
                            default {
                                [DateTime]::ParseExact(($PSItem.Split('+|-')[0]), 'yyyyMMddHHmmss.ffffff', [System.Globalization.CultureInfo]::InvariantCulture)
                            }
                        } 
                        $Result['ExpirationMessageSentIsGMT'] = $Trigger.ExpirationMessageSentIsGMT
                        $Result['LastTriggerTime'] = switch($Trigger.LastTriggerTime) {
                            $null {
                                continue
                            }
                            default {
                                [DateTime]::ParseExact(($PSItem.Split('+|-')[0]), 'yyyyMMddHHmmss.ffffff', [System.Globalization.CultureInfo]::InvariantCulture)
                            }
                        } 
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