PsEnv
=====

A simple PowerShell module that allows specific tools to be added to the current
environment by updating environment variables from a JSON file.  For example:

    Use-Tool -ToolName msvc10 -ToolSpec x86

Could be used to make the 32 bit Microsoft VisualC++ compiler available in the
current PowerShell session.  An alias allows the above to reduce to simply
`use msvc10`.  All tools and specs are stored in a JSON file described later.


## Motivation

It's surprisingly easy for the `PATH` variable on a development computer to
become completely out of hand.  Especially if you often work with many
different platforms spanning web development and embedded electronics, as I do.
I *solved* this problem a few years back (before discovering PowerShell) by
writing a batch file called 'use' that would update the path for various tools
I did not want on the path permanently.  Unfortunately, because CMD, this batch
file had to be manually modified for every new tool installed.

After discovering PowerShell, it immediately became obvious that it was a far
better environment to work in than CMD but the handy (though awkward) 'use'
batch file would no longer work.  PsEnv is a far fancier solution to that same
problem.  One must still manually modify a file to describe a new environment,
but the description is no longer intermingled with the code.  Instead, all
modifications are contained within a JSON file.


## Commands

### Use-Tool

    Use-Tool [-ToolName] <String> [[-ToolSpec] <String>]
        [[-DeferredArgs] <String[]>]

Use-Tool will modify the environment variables of the currently active
PowerShell session to meet the requirements for some external tool or script.
The `PATH` variable is treated separately because it is the most likely to be
modified.  In fact, the `PATH` variable is the reason this function even exists.
On a system with many developer tools instead, it can be very easy for `PATH` to
become unwieldy.  With Use-Tool, a short `PATH` containing only essential
directories can be used most of the time, and then additional tools can be added
as required.

| Parameter | Description
| --------- | -----------
| `[-ToolName] <String>` | The tool environment to use from the configuration
|                        | file.


.PARAMETER ToolSpec

A named spec under the requested environment.


.PARAMETER DeferredArgs

A list of arguments to offer up to a traditional CMD batch file if a 'defer'
section is specified in the configuration file.


Tool environments are defined in a JSON file that is loaded with the
[Set-PsEnvConfig](#set-psenvconfig) command.  The contents of this file are
parsed and stored in the `PsEnvConfig` global variable.  Neither function
prohibits the modification of this variable by the user, but it is definitely
not advised.  The exact format of the JSON file is documented at
<https://github.com/DuFace/PsEnv>.

Each tool environment is allowed a *spec* which can offer further options for
how the environment will be modified.  An example of this could be in loading a
compiler for either x86 or x86_64 targets.

Modifies the environment variables

TODO: Describe `Set-PsEnvConfig` and `Use-Tool` (`use`) here.


## JSON environment description format

TODO.


## Examples

TODO.


## Credits

Deferred environment modifications (i.e., support for legacy batch files) is
based on [Robert Anderson](http://rwandering.net/)'s clever solution for
[replacing the Visual Studio command prompt with PowerShell][rwa-vspsh].

[rwa-vspsh]: http://rwandering.net/2006/05/02/vs2005-powershell-prompt/


## Licence

This tool is covered by the MIT licence.
