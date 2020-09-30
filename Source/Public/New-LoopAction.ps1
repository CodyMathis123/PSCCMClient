function New-LoopAction {
    param
    (
        [parameter(Mandatory = $true, ParameterSetName = 'DoUntil')]
        [int32]$LoopTimeout,
        [parameter(Mandatory = $true, ParameterSetName = 'DoUntil')]
        [ValidateSet('Seconds', 'Minutes', 'Hours', 'Days')]
        [string]$LoopTimeoutType,
        [parameter(Mandatory = $true)]
        [int32]$LoopDelay,
        [parameter(Mandatory = $false, ParameterSetName = 'DoUntil')]
        [ValidateSet('Milliseconds', 'Seconds', 'Minutes')]
        [string]$LoopDelayType = 'Seconds',
        [parameter(Mandatory = $true, ParameterSetName = 'ForLoop')]
        [int32]$Iterations,
        [parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        [parameter(Mandatory = $true, ParameterSetName = 'DoUntil')]
        [parameter(Mandatory = $false, ParameterSetName = 'ForLoop')]
        [scriptblock]$ExitCondition,
        [parameter(Mandatory = $false)]
        [scriptblock]$IfTimeoutScript,
        [parameter(Mandatory = $false)]
        [scriptblock]$IfSucceedScript
    )
    begin {
        switch ($PSCmdlet.ParameterSetName) {
            'DoUntil' {
                $paramNewTimeSpan = @{
                    $LoopTimeoutType = $LoopTimeout
                }    
                $TimeSpan = New-TimeSpan @paramNewTimeSpan
                $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
                $FirstRunDone = $false        
            }
        }
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'DoUntil' {
                do {
                    switch ($FirstRunDone) {
                        $false {
                            $FirstRunDone = $true
                        }
                        Default {
                            $paramStartSleep = @{
                                $LoopDelayType = $LoopDelay
                            }
                            Start-Sleep @paramStartSleep
                        }
                    }
                    $ScriptBlock.Invoke()
                }
                until ($ExitCondition.Invoke() -or $StopWatch.Elapsed -ge $TimeSpan)
            }
            'ForLoop' {
                for ($i = 0; $i -lt $Iterations; $i++) {
                    switch ($FirstRunDone) {
                        $false {
                            $FirstRunDone = $true
                        }
                        Default {
                            $paramStartSleep = @{
                                $LoopDelayType = $LoopDelay
                            }
                            Start-Sleep @paramStartSleep
                        }
                    }
                    $ScriptBlock.Invoke()
                    if ($PSBoundParameters.ContainsKey('ExitCondition')) {
                        if ($ExitCondition.Invoke()) {
                            break
                        }
                    }
                }
            }
        }
    }
    end {
        switch ($PSCmdlet.ParameterSetName) {
            'DoUntil' {
                if ((-not $ExitCondition.Invoke()) -and $StopWatch.Elapsed -ge $TimeSpan -and $PSBoundParameters.ContainsKey('IfTimeoutScript')) {
                    $IfTimeoutScript.Invoke()
                }
                if ($ExitCondition.Invoke() -and $PSBoundParameters.ContainsKey('IfSucceedScript')) {
                    $IfSucceedScript.Invoke()
                }
                $StopWatch.Reset()
            }
            'ForLoop' {
                if ($PSBoundParameters.ContainsKey('ExitCondition')) {
                    if ((-not $ExitCondition.Invoke()) -and $i -ge $Iterations -and $PSBoundParameters.ContainsKey('IfTimeoutScript')) {
                        $IfTimeoutScript.Invoke()
                    }
                    elseif ($ExitCondition.Invoke() -and $PSBoundParameters.ContainsKey('IfSucceedScript')) {
                        $IfSucceedScript.Invoke()
                    }
                }
                else {
                    if ($i -ge $Iterations -and $PSBoundParameters.ContainsKey('IfTimeoutScript')) {
                        $IfTimeoutScript.Invoke()
                    }
                    elseif ($i -lt $Iterations -and $PSBoundParameters.ContainsKey('IfSucceedScript')) {
                        $IfSucceedScript.Invoke()
                    }
                }
            }
        }
    }
}
