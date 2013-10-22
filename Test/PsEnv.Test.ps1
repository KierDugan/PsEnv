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
    Assert-That -ActualValue $env:FOO -Constraint {
        $ActualValue -eq 'Hello'
    }
    Assert-That -ActualValue $env:BAR -Constraint {
        $ActualValue -eq 'World!'
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
    Assert-That -ActualValue $env:FOO -Constraint {
        $ActualValue -eq 'Hello, World!'
    }
    Assert-That -ActualValue $env:BAR -Constraint {
        $ActualValue -eq 'Hello, World!'
    }
    Assert-That -ActualValue $env:BAZ -Constraint {
        $ActualValue -eq 'appended'
    }
    Assert-That -ActualValue $env:FOT -Constraint {
        $ActualValue -eq 'prepended'
    }
}

function Test.Use-Tool_BazAndFotDeleted_BazAndFotDummyValues() {
    ## Arrange
    Set-PsEnvConfig .\PsEnvTools.json
    $env:BAZ, $env:FOT = 'baz dummy', 'fot dummy'

    ## Act
    Use-Tool -ToolName test -ToolSpec 'delete-test'

    ## Assert
    Assert-That -ActualValue $env:path -Constraint { -not $env:BAZ }
    Assert-That -ActualValue $env:path -Constraint { -not $env:FOT }
}

function Test.Use-Tool_PathAlteredAndFooSet_FooNotSetPathSetDummy() {
    # Save the path
    $PathBeforeTest = $env:path

    ## Arrange
    Set-PsEnvConfig .\PsEnvTools.json
    $env:FOO = $null

    ## Act
    Use-Tool -ToolName 'batch-test'

    ## Assert
    Assert-That -ActualValue $env:path -Constraint {
        $ActualValue -eq ".;..;$PathBeforeTest"
    }
    Assert-That -ActualValue $env:FOO -Constraint {
        $ActualValue -eq "Hello, World!"
    }

    # Restore path
    $env:path = $PathBeforeTest
}
