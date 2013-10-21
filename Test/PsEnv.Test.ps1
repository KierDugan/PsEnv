. PSUnit.ps1
Import-Module -Force ..\PsEnv.psm1

function Test.Use-Tool_PathHasDotAndDoubleDotPrepended_PathEqualsDummy() {
    # Save the path
    $PathBeforeTest = $env:path

    ## Arrange
    Set-PsEnvConfig .\PsEnvTools.json

    ## Act
    Use-Tool -ToolName test -ToolSpec path

    ## Assert
    Assert-That -ActualValue $env:path -Constraint {
        $ActualValue -eq ".;..;$PathBeforeTest"
    }

    # Restore the path
    $env:path = $PathBeforeTest
}

function Test.Use-Tool_FooAndBarVariablesCreated_FooAndBarNullified() {
    ## Arrange
    Set-PsEnvConfig .\PsEnvTools.json
    $env:FOO = $env:BAR = $null

    ## Act
    Use-Tool -ToolName test -ToolSpec 'set-test'

    ## Assert
    Assert-That -ActualValue $env:path -Constraint {
        (($env:FOO -eq 'Hello') -and ($env:BAR -eq 'World!'))
    }
}

function Test.Use-Tool_FooAndBarEqualToHelloWorld_FooAndBarHelloAndWorld()
{
    ## Arrange
    Set-PsEnvConfig .\PsEnvTools.json
    $env:FOO, $env:BAR  = 'Hello', 'World!'
    $env:BAZ = $env:FOT = $null

    ## Act
    Use-Tool -ToolName test -ToolSpec 'modify-test'

    ## Assert
    Assert-That -ActualValue $env:path -Constraint {
        (($env:FOO -eq 'Hello, World!') -and
            ($env:BAR -eq 'Hello, World!') -and
            ($env:BAZ -eq 'appended') -and
            ($env:FOT -eq 'prepended'))
    }
}

function Test.Use-Tool_BazAndFotDeleted_BazAndFotDummyValues() {
    ## Arrange
    Set-PsEnvConfig .\PsEnvTools.json
    $env:BAZ, $env:FOT = 'baz dummy', 'fot dummy'

    ## Act
    Use-Tool -ToolName test -ToolSpec 'delete-test'

    ## Assert
    Assert-That -ActualValue $env:path -Constraint {
        ((-not $env:BAZ) -and (-not $env:FOT))
    }
}
