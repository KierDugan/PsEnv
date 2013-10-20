param([String[]] $tools)

# Configuration variables
$configFile = '.\PsEnvTools.json'

# Load the tools from the file
$config = (Get-Content $configFile) -join "`n" | ConvertFrom-Json

# Utility functions
function GetJsonKeys($jsonObject) {
    return Get-Member -InputObject $jsonObject -MemberType NoteProperty |
        ForEach-Object -MemberName 'Name'
}

# Workhorse function
function Activate-Tool {
    param (
        [String] $tool
    )

    process {
        # Split the tool name into a spec and any arguments to give to an
        # external tool
        $toolName, $toolSpecName, $toolArgs = $tool -split ':'
        $toolName = $toolName.ToLower()

        # Simple check:
        $details = $config.$toolName
        if (-not $details) {
            Write-Output "$tool is not a valid key!"
            return
        }

        # Extract the correct tool spec
        if (-not $toolSpecName) {
            $toolSpec = $details[0]
        } else {
            foreach ($spec in $details) {
                if ($spec.'name' -eq $toolSpecName) {
                    # Found it!
                    $toolSpec = $spec
                    break
                }
            }
        }

        if (-not $toolSpec) {
            Write-Output "$toolSpecName is not a valid spec for $toolName."
            return
        }

        # Break the tool spec out into objects
        $toolDisplay = $toolSpec.display
        $toolPath    = $toolSpec.path
        $toolSet     = $toolSpec.set
        $toolDelete  = $toolSpec.delete
        $toolAppend  = $toolSpec.append
        $toolPrepend = $toolSpec.prepend
        $toolDefer   = $toolSpec.defer

        if ($toolDisplay) {
            $name = $toolDisplay
        }
        Write-Output "Configuring $name environment:"

        # Update the PATH variable separately
        if ($toolPath) {
            # Prepend the path
            $env:path = ($toolPath -join ';') + ';' + $env:path
            Write-Output "  Updated path."
        }

        # Create any new variables
        if ($toolSet) {
            foreach ($key in GetJsonKeys($toolSet)) {
                $value = $toolSet.$key

                # Actually create the variable
                if ($value) {
                    [Environment]::SetEnvironmentVariable($key, $value)
                }
            }

            Write-Output "  Created new variables."
        }

        # Extend existing variables
        if ($toolAppend) {
            foreach ($key in GetJsonKeys($toolAppend)) {
                $value = $toolAppend.$key

                # Update the variable
                if ($value) {
                    $value = [Environment]::GetEnvironmentVariable($key) + $value
                    [Environment]::SetEnvironmentVariable($key, $value)
                }
            }

            Write-Output "  Appended new data to variables."
        }

        if ($toolPrepend) {
            foreach ($key in GetJsonKeys($toolPrepend)) {
                $value = $toolPrepend.$key

                # Update the variable
                if ($value) {
                    $value += [Environment]::GetEnvironmentVariable($key)
                    [Environment]::SetEnvironmentVariable($key, $value)
                }
            }

            Write-Output "  Prepended new data to variables."
        }

        # Delete existing variables
        if ($toolDelete) {
            foreach ($key in $toolDelete) {
                [Environment]::SetEnvironmentVariable($key, $null)
            }

            Write-Output "  Deleted variables."
        }

        # Defer allows legacy batch scripts to be executed
        if ($toolDefer) {
            # Based heavily on the work at:
            #  http://allen-mack.blogspot.co.uk/2008/03/replace-visual-studio-command-prompt.html

            # Assemble the command string
            $command = ''
            foreach ($chunk in $toolDefer) {
                if ($chunk -match " ") {
                    $command += "`"$chunk`" "
                } else {
                    $command += "$chunk "
                }
            }
            $command += $toolArgs -join ' '

            # Use the normal command prompt to execute the command
            cmd /c "$command & set" | foreach  {
                # Look for every variable line and merge the child environment
                # into the parent
                if ($_ -match '=') {
                    $key, $value = $_.Split('=')
                    [Environment]::SetEnvironmentVariable($key, $value)
                }
            }

            Write-Output "  Executed command: $command"
        }
    }
}

# Activate each tool specified on the command line
foreach ($tool in $tools) {
    # Simple case insensitive comparison
    Activate-Tool $tool
}


