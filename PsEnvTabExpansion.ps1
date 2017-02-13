
function script:GetEnvironmentToolNames() {
    return [array](Get-Member -InputObject $Global:PsEnvConfig -MemberType NoteProperty | ForEach-Object -MemberName 'Name')
}

function script:GetEnvironmentSpecNames() {
    Param($toolName)
    #    Write-Host "GetEnvironmentSpecNames ", $toolName
    return $Global:PsEnvConfig.$toolName | ForEach-Object{$_.name}
}

function script:GetAliasPattern($command) {
    $aliases = @($command) + @(Get-Alias | Where-Object { $_.Definition -eq $command } | select -Exp Name)
    "($($aliases -join '|'))"
}

function PsEnvTabExpansion($lastBlock) {
    $patten = "^(?<toolname>$((GetEnvironmentToolNames) -join '|'))\s+(?<toolspec>\S*)"

    switch -regex ($lastBlock -replace "^$(GetAliasPattern use-tool)\s+","") {

        # Handles git <cmd> <op>
        "^(?<toolname>$((GetEnvironmentToolNames) -join '|'))\s+(?<toolspec>\S*)" {
            (GetEnvironmentSpecNames $matches['toolname']) -like  ("{0}*" -f $matches['toolspec'])
        }
   
        # Handles use <toolname>
        "^(?<toolname>\S*)$" {
            (GetEnvironmentToolNames) -like ("{0}*" -f $matches['toolname'])
        }
    }
}

if (Test-Path Function:\TabExpansion) {
    Rename-Item Function:\TabExpansion TabExpansionBackup
}

function TabExpansion($line, $lastWord) {
    # Write-Host $line, $lastWord -ForegroundColor Red

    $lastBlock = [regex]::Split($line, '[|;]')[-1].TrimStart()

    # Write-Host "^$(GetAliasPattern use-tool) (.*)" -ForegroundColor Red

    # Write-Host ("*{0}*" -f $lastBlock) -ForegroundColor Red
    switch -regex ($lastBlock) {

        # Execute psenv tab completion for all use-tool commands
        "^$(GetAliasPattern use-tool) (.*)" { 
            # Write-Host "matchd" -ForegroundColor Red
        
            PsEnvTabExpansion $lastBlock 
        }
        # Fall back on existing tab expansion
        default {
            if (Test-Path Function:\TabExpansionBackup) {
                TabExpansionBackup $line $lastWord 
            } 
        }
    }
}
