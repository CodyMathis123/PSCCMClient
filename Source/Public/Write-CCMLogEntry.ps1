Function Write-CCMLogEntry {
    param (
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Message', 'ToLog')]
        [string[]]$Value,
        [parameter(Mandatory = $false)]
        [ValidateSet('Informational', 'Warning', 'Error', '1', '2', '3')]
        [string]$Severity = 'Informational',
        [parameter(Mandatory = $false)]
        [string]$Component,
        [parameter(Mandatory = $true)]
        [string]$FileName,
        [parameter(Mandatory = $false)]
        [string]$Folder = (Get-Location).Path,
        [parameter(Mandatory = $false)]
        [int]$Bias = [System.DateTimeOffset]::Now.Offset.TotalMinutes,
        [parameter(Mandatory = $false)]
        [int]$MaxLogFileSize = 5MB,
        [parameter(Mandatory = $false)]
        [int]$LogsToKeep = 0
    )
    begin {
        # Convert Severity to integer log level
        [int]$LogLevel = switch ($Severity) {
            Informational {
                1
            }
            Warning {
                2
            }
            Error {
                3
            }
            default {
                $PSItem
            }
        }

        # Determine log file location
        $LogFilePath = Join-Path -Path $Folder -ChildPath $FileName

        #region log rollover check if $MaxLogFileSize is greater than 0
        switch (([System.IO.FileInfo]$LogFilePath).Exists -and $MaxLogFileSize -gt 0) {
            $true {
                #region rename current file if $MaxLogFileSize exceeded, respecting $LogsToKeep
                switch (([System.IO.FileInfo]$LogFilePath).Length -ge $MaxLogFileSize) {
                    $true {
                        # Get log file name without extension
                        $LogFileNameWithoutExt = $FileName -replace ([System.IO.Path]::GetExtension($FileName))

                        # Get already rolled over logs
                        $AllLogs = Get-ChildItem -Path $Folder -Name "$($LogFileNameWithoutExt)_*" -File

                        # Sort them numerically (so the oldest is first in the list)
                        $AllLogs = Sort-Object -InputObject $AllLogs -Descending -Property { $_ -replace '_\d+\.lo_$' }, { [int]($_ -replace '^.+\d_|\.lo_$') } -ErrorAction Ignore

                        foreach ($Log in $AllLogs) {
                            # Get log number
                            $LogFileNumber = [int][Regex]::Matches($Log, "_([0-9]+)\.lo_$").Groups[1].Value
                            switch (($LogFileNumber -eq $LogsToKeep) -and ($LogsToKeep -ne 0)) {
                                $true {
                                    # Delete log if it breaches $LogsToKeep parameter value
                                    [System.IO.File]::Delete("$($Folder)\$($Log)")
                                }
                                $false {
                                    # Rename log to +1
                                    $NewFileName = $Log -replace "_([0-9]+)\.lo_$", "_$($LogFileNumber+1).lo_"
                                    [System.IO.File]::Copy("$($Folder)\$($Log)", "$($Folder)\$($NewFileName)", $true)
                                }
                            }
                        }

                        # Copy main log to _1.lo_
                        [System.IO.File]::Copy($LogFilePath, "$($Folder)\$($LogFileNameWithoutExt)_1.lo_", $true)

                        # Blank the main log
                        $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $LogFilePath, $false
                        $StreamWriter.Close()
                    }
                }
                #endregion rename current file if $MaxLogFileSize exceeded, respecting $LogsToKeep
            }
        }
        #endregion log rollover check if $MaxLogFileSize is greater than 0

        # Construct date for log entry
        $Date = (Get-Date -Format 'MM-dd-yyyy')

        # Construct context for log entry
        try {
            $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
        }
        catch {
            $Context = switch ((Get-ChildItem -Path env:).Key) {
                Username {
                    $env:USERNAME
                }
                User {
                    $env:USER
                }
            }
        }
    }
    process {
        foreach ($MSG in $Value) {
            #region construct time stamp for log entry based on $Bias and current time
            $Time = switch -regex ($Bias) {
                '-' {
                    [string]::Concat($(Get-Date -Format 'HH:mm:ss.fff'), $Bias)
                }
                Default {
                    [string]::Concat($(Get-Date -Format 'HH:mm:ss.fff'), '+', $Bias)
                }
            }
            #endregion construct time stamp for log entry based on $Bias and current time

            #region construct the log entry according to CMTrace format
            $LogText = [string]::Format('<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="{4}" type="{5}" thread="{6}" file="">', $MSG, $Time, $Date, $Component, $Context, $LogLevel, $PID)
            #endregion construct the log entry according to CMTrace format

            #region add value to log file
            try {
                $StreamWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $LogFilePath, 'Append'
                $StreamWriter.WriteLine($LogText)
                $StreamWriter.Close()
            }
            catch [System.Exception] {
                Write-Warning -Message "Unable to append log entry to $FileName file. Error message: $($_.Exception.Message)"
            }
            #endregion add value to log file
        }
    }
}