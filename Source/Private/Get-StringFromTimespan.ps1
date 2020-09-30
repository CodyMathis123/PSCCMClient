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

    $DescriptiveTSArray = switch ('Days', 'Hours', 'Minutes', 'Seconds', 'Milliseconds') {
        default {
            $TimeIncrement = $PSItem
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
    }

    switch ($DescriptiveTSArray.Count) {
        0 {
            $PSItem
        }
        default {
            [string]::Join(' ', $DescriptiveTSArray)
        }
    }
}