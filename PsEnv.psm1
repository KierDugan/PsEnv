##
##  PsEnv, a simple tool-specific environment management for PowerShell.
##  URL: https://github.com/DuFace/PsEnv
##  Copyright (c) 2013 Kier Dugan
##

## Utility functions -----------------------------------------------------------
function GetJsonKeys($jsonObject) {
    return Get-Member -InputObject $jsonObject -MemberType NoteProperty |
        ForEach-Object -MemberName 'Name'
}

function GetEnvironmentSpec($ToolName, $ToolSpec) {
    # Get the current environment description
    $details = $Global:PsEnvConfig.$ToolName

    # Extract the correct tool spec
    if (-not $ToolSpec) {
        Write-Debug "No spec given; using first in array."
        $spec = $details[0]

        if (-not $spec) {
            Write-Error "$ToolName has no environment specifications."
        }
    } else {
        Write-Debug "Spec given; searching..."
        foreach ($s in $details) {
            if ([String]::Compare($s.name, $ToolSpec, $true) -eq 0) {
                # Found it!
                $spec = $s
                break
            }
        }

        if (-not $spec) {
            Write-Error "$ToolSpec is not a valid spec for $toolName."
        }
    }

    return $spec
}


## Commands --------------------------------------------------------------------

<#
.SYNOPSIS

Loads a JSON configuration file containing a list of environments that can be
used with Use-Tool.


.DESCRIPTION

This function must be called before any calls to Use-Tool.  Ideally a call
should be placed in your $Profile to ensure this information is readily
available.  Any modifications to your environment description JSON file must be
loaded by Set-PsEnvConfig before any Use-Tool calls can make use of it.


.PARAMETER ConfigFile

Path to a JSON environment description file to load for Use-Tool.


.LINK
https://github.com/DuFace/PsEnv
Use-Tool
#>
function Set-PsEnvConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateScript({ Test-Path $_ -PathType 'Leaf' })]
        [String]
        $ConfigFile
    )

    process {
        # Load the specified JSON file into a global variable
        $Global:PsEnvConfig = (Get-Content $ConfigFile) -join "`n" |
            ConvertFrom-Json
    }
}


<#
.SYNOPSIS

Updates the current environment with variables defined in the configuration JSON
file specifed by Set-PsEnvConfig.


.DESCRIPTION

Use-Tool will modify the environment variables of the currently active
PowerShell session to meet the requirements for some external tool or script.
The PATH variable is treated separately because it is the most likely to be
modified.  In fact, the PATH variable is the reason this function even exists.
On a system with many developer tools installed, it can be very easy for PATH to
become unwieldy.  With Use-Tool, a short PATH containing only essential
directories can be used most of the time, and then additional tools can be added
as required.

Tool environments are defined in a JSON file that is loaded with the
Set-PsEnvConfig command.  The contents of this file are parsed and stored in the
PsEnvConfig global variable.  Neither function prohibits the modification of
this variable by the user, but it is definitely not advised.  The exact format
of the JSON file is documented at <https://github.com/DuFace/PsEnv>.

Each tool environment is allowed a 'spec' which can offer further options for
how the environment will be modified.  An example of this could be in loading a
compiler for either x86 or x86_64 targets.


.PARAMETER ToolName

The tool environment to use from the configuration file.


.PARAMETER ToolSpec

A named spec under the requested environment.


.PARAMETER DeferredArgs

A list of arguments to offer up to a traditional CMD batch file if a 'defer'
section is specified in the configuration file.


.NOTES

Executing this command before Set-PsEnvConfig will inevitably result in a
failure as no configuration information will exist.  Don't do that.


.LINK
https://github.com/DuFace/PsEnv
Set-PsEnvConfig
#>
function Use-Tool {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateScript({ $Global:PsEnvConfig.$_ -ne $null })]
        [String] $ToolName,

        [Parameter(Mandatory=$false, ValueFromPipeline=$false)]
        [String] $ToolSpec,

        [Parameter(Mandatory=$false, ValueFromPipeline=$false)]
        [String[]] $DeferredArgs
    )

    process {
        # Get the current environment description
        if (-not ($spec = GetEnvironmentSpec $ToolName $ToolSpec)) {
            Write-Error "Failed to load tool spec ${ToolName}:${ToolSpec}."
            return
        }

        # Break the tool spec out into objects
        $toolDisplay = $spec.display
        $toolPath    = $spec.path
        $toolSet     = $spec.set
        $toolDelete  = $spec.delete
        $toolAppend  = $spec.append
        $toolPrepend = $spec.prepend
        $toolDefer   = $spec.defer

        if (-not $toolDisplay) {
            $toolDisplay = $ToolName
        }
        Write-Output "Configuring $toolDisplay environment."

        # Update the PATH variable separately
        if ($toolPath) {
            # Prepend the path
            $env:path = ($toolPath -join ';') + ';' + $env:path
            Write-Verbose "  Updated path."
        }

        # Create any new variables
        if ($toolSet) {
            foreach ($key in GetJsonKeys $toolSet) {
                $value = $toolSet.$key

                # Actually create the variable
                if ($value) {
                    [Environment]::SetEnvironmentVariable($key, $value)
                }
            }

            Write-Verbose "  Created new variables."
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

            Write-Verbose "  Appended new data to variables."
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

            Write-Verbose "  Prepended new data to variables."
        }

        # Delete existing variables
        if ($toolDelete) {
            foreach ($key in $toolDelete) {
                [Environment]::SetEnvironmentVariable($key, $null)
            }

            Write-Verbose "  Deleted variables."
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
            $command += $DeferredArgs -join ' '

            # Use the normal command prompt to execute the command
            cmd /c "$command & set" | foreach  {
                # Look for every variable line and merge the child environment
                # into the parent
                if ($_ -match '=') {
                    $key, $value = $_.Split('=')
                    [Environment]::SetEnvironmentVariable($key, $value)
                }
            }

            Write-Verbose "  Executed command: $command"
        }
    }
}


## Exported commands and aliases -----------------------------------------------
Set-Alias use Use-Tool

Export-ModuleMember Set-PsEnvConfig
Export-ModuleMember Use-Tool
Export-ModuleMember -Alias use
