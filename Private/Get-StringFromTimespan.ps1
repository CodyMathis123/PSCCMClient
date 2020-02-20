function Get-StringFromTimespan {
    <#
        .SYNOPSIS
            Return a descriptive string based on timespan input
        .DESCRIPTION
            Reutrn a string describing a timespace, such as '1 day, 3 hours, 10 seconds'
            This is helpful when you desire to output a length of time in an easily readible
            format. The function accepts either a proper [timespan] as input, or you can
            alternatively provide the various time intervals that comprise a timespan.
        .PARAMETER Days
            The integer count of Days you wish to convert to a 'human readable string'
        .PARAMETER Hours
            The integer count of Hours you wish to convert to a 'human readable string'
        .PARAMETER Minutes
            The integer count of Minutes you wish to convert to a 'human readable string'
        .PARAMETER Seconds
            The integer count of Seconds you wish to convert to a 'human readable string'
        .PARAMETER Milliseconds
            The integer count of Milliseconds you wish to convert to a 'human readable string'
        .PARAMETER TimeSpan
            A timespan object you wish to convert to a 'human readable string'
        .EXAMPLE
            C:\PS> Get-StringFromTimespan -Seconds 3630
                1 Hour 30 Seconds
        .EXAMPLE
            C:\PS> $TS = New-TimeSpan -Hours 123 -Minutes 234
                Get-StringFromTimespan -TimeSpan $TS

                5 Days 6 Hours 54 Minutes
        .NOTES
            FileName:    Get-StringFromTimespan.ps1
            Author:      Cody Mathis
            Contact:     @CodyMathis123
            Created:     2020-02-20
            Updated:     2020-02-20
    #>
    param(
        [parameter(Mandatory = $false, ParameterSetName = 'ByTimeInterval')]
        [int]$Days,
        [parameter(Mandatory = $false, ParameterSetName = 'ByTimeInterval')]
        [int]$Hours,
        [parameter(Mandatory = $false, ParameterSetName = 'ByTimeInterval')]
        [int]$Minutes,
        [parameter(Mandatory = $false, ParameterSetName = 'ByTimeInterval')]
        [int]$Seconds,
        [parameter(Mandatory = $false, ParameterSetName = 'ByTimeInterval')]
        [int]$Milliseconds,
        [parameter(Mandatory = $true, ParameterSetName = 'ByTimeSpan')]
        [timespan]$TimeSpan
    )

    $TS = switch ($PSCmdlet.ParameterSetName) {
        'ByTimeInterval' {
            New-TimeSpan @PSBoundParameters
        }
        'ByTimeSpan' {
            Write-Output $TimeSpan
        }
    }

    $DescriptiveTSArray = foreach ($TimeIncrement in 'Days', 'Hours', 'Minutes', 'Seconds', 'Milliseconds') {
        switch ($TS.$TimeIncrement) {
            0 {
                continue
            }
            1 {
                [string]::Format('{0} {1}', $PSItem, ($TimeIncrement -replace 's$'))
            }
            default {
                [string]::Format('{0} {1}', $PSItem, $TimeIncrement)
            }
        }
    }

    [string]::Join(' ', $DescriptiveTSArray)
}