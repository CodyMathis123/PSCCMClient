function Get-StringFromTimespan {
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

    $TimeSpanStringArray = foreach ($TimeIncrement in 'Days', 'Hours', 'Minutes', 'Seconds', 'Milliseconds') {
        switch ($TS.$TimeIncrement) {
            0 {
                continue
            }
            default {
                [string]::Format('{0} {1}', $PSItem, ($TimeIncrement -replace 's$', '(s)'))
            }
        }
    }
    [string]::Join(' ', $TimeSpanStringArray)
}