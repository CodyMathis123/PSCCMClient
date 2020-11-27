---
external help file: PSCCMClient-help.xml
Module Name: PSCCMClient
online version:
schema: 2.0.0
---

# New-LoopAction

## SYNOPSIS
Function to loop a specified scriptblock until certain conditions are met

## SYNTAX

### DoUntil
```
New-LoopAction -LoopTimeout <Int32> -LoopTimeoutType <String> -LoopDelay <Int32> [-LoopDelayType <String>]
 -ScriptBlock <ScriptBlock> -ExitCondition <ScriptBlock> [-IfTimeoutScript <ScriptBlock>]
 [-IfSucceedScript <ScriptBlock>] [<CommonParameters>]
```

### ForLoop
```
New-LoopAction -LoopDelay <Int32> -Iterations <Int32> -ScriptBlock <ScriptBlock> [-ExitCondition <ScriptBlock>]
 [-IfTimeoutScript <ScriptBlock>] [-IfSucceedScript <ScriptBlock>] [<CommonParameters>]
```

## DESCRIPTION
This function is a wrapper for a ForLoop or a DoUntil loop.
This allows you to specify if you want to exit based on a timeout, or a number of iterations.
    Additionally, you can specify an optional delay between loops, and the type of dealy (Minutes, Seconds).
If needed, you can also perform an action based on
    whether the 'Exit Condition' was met or not.
This is the IfTimeoutScript and IfSucceedScript.

## EXAMPLES

### EXAMPLE 1
```
$newLoopActionSplat = @{
            LoopTimeoutType = 'Seconds'
            ScriptBlock = { 'Bacon' }
            ExitCondition = { 'Bacon' -Eq 'eggs' }
            IfTimeoutScript = { 'Breakfast'}
            LoopDelayType = 'Seconds'
            LoopDelay = 1
            LoopTimeout = 10
        }
        New-LoopAction @newLoopActionSplat
        Bacon
        Bacon
        Bacon
        Bacon
        Bacon
        Bacon
        Bacon
        Bacon
        Bacon
        Bacon
        Bacon
        Breakfast
```

### EXAMPLE 2
```
$newLoopActionSplat = @{
            ScriptBlock = { if($Test -eq $null){$Test = 0};$TEST++ }
            ExitCondition = { $Test -eq 4 }
            IfTimeoutScript = { 'Breakfast' }
            IfSucceedScript = { 'Dinner'}
            Iterations  = 5
            LoopDelay = 1
        }
        New-LoopAction @newLoopActionSplat
        Dinner
C:\PS> $newLoopActionSplat = @{
            ScriptBlock = { if($Test -eq $null){$Test = 0};$TEST++ }
            ExitCondition = { $Test -eq 6 }
            IfTimeoutScript = { 'Breakfast' }
            IfSucceedScript = { 'Dinner'}
            Iterations  = 5
            LoopDelay = 1
        }
        New-LoopAction @newLoopActionSplat
        Breakfast
```

## PARAMETERS

### -LoopTimeout
A time interval integer which the loop should timeout after.
This is for a DoUntil loop.

```yaml
Type: Int32
Parameter Sets: DoUntil
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -LoopTimeoutType
Provides the time increment type for the LoopTimeout, defaulting to Seconds.
('Seconds', 'Minutes', 'Hours', 'Days')

```yaml
Type: String
Parameter Sets: DoUntil
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LoopDelay
An optional delay that will occur between each loop.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -LoopDelayType
Provides the time increment type for the LoopDelay between loops, defaulting to Seconds.
('Milliseconds', 'Seconds', 'Minutes')

```yaml
Type: String
Parameter Sets: DoUntil
Aliases:

Required: False
Position: Named
Default value: Seconds
Accept pipeline input: False
Accept wildcard characters: False
```

### -Iterations
Implies that a ForLoop is wanted.
This will provide the maximum number of Iterations for the loop.
\[i.e.
"for ($i = 0; $i -lt $Iterations; $i++)..."\]

```yaml
Type: Int32
Parameter Sets: ForLoop
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ScriptBlock
A script block that will run inside the loop.
Recommend encapsulating inside { } or providing a \[scriptblock\]

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExitCondition
A script block that will act as the exit condition for the do-until loop.
Will be evaluated each loop.
Recommend encapsulating inside { } or providing a \[scriptblock\]

```yaml
Type: ScriptBlock
Parameter Sets: DoUntil
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: ScriptBlock
Parameter Sets: ForLoop
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IfTimeoutScript
A script block that will act as the script to run if the timeout occurs.
Recommend encapsulating inside { } or providing a \[scriptblock\]

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IfSucceedScript
A script block that will act as the script to run if the exit condition is met.
Recommend encapsulating inside { } or providing a \[scriptblock\]

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

Play with the conditions a bit.
I've tried to provide some examples that demonstrate how the loops, timeouts, and scripts work!

## RELATED LINKS
