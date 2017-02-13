# Ideas from the Awesome Posh-Git - https://github.com/dahlbyk/posh-git
# Posh-Git License - https://github.com/dahlbyk/posh-git/blob/1941da2472eb668cde2d6a5fc921d5043a024386/LICENSE.txt
# http://www.jeremyskinner.co.uk/2010/03/07/using-git-with-windows-powershell/

function script:GetEnvironmentToolNames() {
    return Get-Member -InputObject $Global:PsEnvConfig -MemberType NoteProperty | ForEach-Object -MemberName 'Name'
}

function script:GetEnvironmentSpecNames() {
    Param($toolName)
    $results = $Global:PsEnvConfig.$toolName | ForEach-Object{$_.name}
    if($null -eq $resuls){
        return @()
    }
    else {
        return $results
    }
}

function script:GetAliasPattern($command) {
    $aliases = @($command) + @(Get-Alias | Where-Object { $_.Definition -eq $command } | Select-Object -Exp Name)
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
