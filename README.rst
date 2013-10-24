*****
PsEnv
*****

A simple PowerShell module that allows specific tools to be added to the current
environment by updating environment variables from a JSON file.  For example::

    Use-Tool -ToolName msvc10 -ToolSpec x86

Could be used to make the 32 bit Microsoft Visual C++ compiler available in the
current PowerShell session.  An alias allows the above to reduce to simply
``use msvc10``.  All tools and specs are stored in a JSON file described later.


Motivation
==========

It's surprisingly easy for the ``PATH`` variable on a development computer to
become completely out of hand.  Especially if you often work with many
different platforms spanning web development and embedded electronics, as I do.
I "solved" this problem a few years back (before discovering PowerShell) by
writing a batch file called 'use' that would update the path for various tools
I did not want on the path permanently.  Unfortunately, because CMD, this batch
file had to be manually modified for every new tool installed.

After discovering PowerShell, it immediately became obvious that it was a far
better environment to work in than CMD, but the handy (though awkward) 'use'
batch file would no longer work.  PsEnv is a far fancier solution to that same
problem.  One must still manually modify a file to describe a new environment,
but the description is no longer intermingled with the code.  Instead, all
of the information is contained within a JSON file.


Commands
========

Use-Tool
--------

.. code:: PowerShell

    Use-Tool [-ToolName] <String> [[-ToolSpec] <String>] [[-DeferredArgs] <String[]>]

`Use-Tool`_ (alias ``use``) will modify the environment variables of the currently active
PowerShell session to meet the requirements for some external tool or script.
The ``PATH`` variable is treated separately because it is the most likely to be
modified.  In fact, the ``PATH`` variable is the reason this function even
exists.  On a system with many developer tools installed, it can be very easy for
``PATH`` to become unwieldy.  With `Use-Tool`_, a short ``PATH`` containing only
essential directories can be used most of the time, and then additional tools
can be added as required.

+------------------------------+-----------------------------------------------+
| Parameter                    | Description                                   |
+==============================+===============================================+
| ``-ToolName <String>``       | The tool environment to use from the          |
|                              | configuration file.                           |
+------------------------------+-----------------------------------------------+
| ``-ToolSpec <String>``       | A named spec under the requested environment. |
+------------------------------+-----------------------------------------------+
| ``-DeferredArgs <String[]>`` | A list of arguments to offer up to a          |
|                              | traditional CMD batch file if a ``defer``     |
|                              | section is specified in the configuration     |
|                              | file.                                         |
+------------------------------+-----------------------------------------------+

Tool environments are defined in a JSON file that is loaded with the
`Set-PsEnvConfig`_ command.  The contents of this file are parsed and stored in
the ``PsEnvConfig`` global variable.  Neither function prohibits the
modification of this variable by the user, but it is definitely not advised.
The exact format of the JSON file is documented at
<https://github.com/DuFace/PsEnv>.

Each tool environment is allowed a *spec* which can offer further options for
how the environment will be modified.  An example of this could be in loading a
compiler for either x86 or x86_64 targets.

Set-PsEnvConfig
---------------

.. code:: PowerShell

    Set-PsEnvConfig [-ConfigFile] <String>

This function must be called before any calls to `Use-Tool`_.  Ideally a call
should be placed in your ``$Profile`` to ensure this information is readily
available.  Any modifications to your environment description JSON file must be
loaded by `Set-PsEnvConfig`_ before any `Use-Tool`_ calls can make use of it.

+--------------------------+------------------------------------------------+
| Parameter                | Description                                    |
+==========================+================================================+
| ``-ConfigFile <String>`` | Path to a JSON environment description file to |
|                          | load for `Use-Tool`_.                          |
+--------------------------+------------------------------------------------+


Installation
============

You can install by executing the following `PsGet`__ command if you have it installed:

.. code:: PowerShell

    Install-Module PsEnv

Alternatively, you can follow these manual steps:

1.  Create a PsEnv directory under your modules directory (you can list your modules
    path by executing ``$env:PSModulePath -split ';'``), and download PsEnv.psm1 into
    it.
2.  Execute ``Import-Module PsEnv`` (you can add this command to your ``$profile``).
3.  Create a JSON environment description file and add ``Set-PsEnvConfig <your-file>.json``
    to your ``$profile``.
4.  Execute ``Use-Tool <tool-name>`` whenever you need to bring tools defined in your
    JSON file into the current session!

.. __: https://github.com/psget/psget


Environment description files
=============================

Environment description files are `JSON <http://json.org/>`_ files that contain
a map of *tools* to an array of *specs* as in the following example:

.. code:: JSON

    {
        "SomeTool":
        [
            {
                "name": "spec1",
                "display": "SomeTool Primary Spec"
            },
            {
                "name": "spec2",
                "display": "SomeTool Alternative Spec"
            }
        ],
        "AnotherTool":
        [
            {
                "display": "AnotherTool Only Spec"
            }
        ]
    }

Several important things are highlighted here:

1.  There is no limit to the number of specs a tool may have.
2.  Specs may have a ``name`` and a ``display``-name but both are optional.  If
    a tool has multiple specs then it is good practice to name each one so that
    it may be used on the command line.
3.  The *first* spec of a tool is the default and will be used if no spec has
    been requested on the command line.

The ``display`` field is only used in telling the user that a tool has been
added to the environment, and if it is absent the tool name will be used
instead.

Modifying the ``PATH``
----------------------

The most common use-case for PsEnv is to add a set of directories to the
``PATH`` environment variable.  This is achieved by specifying an array of
directories under the ``path`` key, as follows:

.. code:: JSON

    {
        "SomeTool":
        [
            {
                "name": "spec1",
                "display": "SomeTool Primary Spec",
                "path":
                [
                    "C:\\SomeTool\\Bin",
                    "C:\\SomeTool\\Contrib\\Bin"
                ]
            }
        ]
    }

Every directory in ``path`` will be joined using a a semicolon and then
**prepended** to the system ``PATH`` variable.  At present, there is no option
to append instead.  A simple usage example could be::

    PS C:\Work> Use-Tool -ToolName SomeTool
    Configuring SomeTool Primary Spec environment.
    PS C:\Work> which SomeTool
    C:\SomeTool\Bin\SomeTool.exe

Modifying other variables
-------------------------

In addition to the ``PATH`` variable, it may be necessary to configure others.
There are four sections available to achieve this: ``set``, ``append``,
``prepend``, and ``delete``.  All of these are key/value pairs of which
variable to modify, except ``delete`` which is simply an array.  They are also
processed in this order so that ``delete`` has the highest precedence.

.. code:: JSON

    {
        "SomeTool":
        [
            {
                "name": "spec1",
                "display": "SomeTool Primary Spec",
                "path":
                [
                    "C:\\SomeTool\\Bin",
                    "C:\\SomeTool\\Contrib\\Bin"
                ],
                "append":
                {
                    "PYTHONPATH": ";C:\\SomeTool\\PyBin"
                },
                "set":
                {
                    "SOMETOOL_SPEC": "primary"
                },
                "delete":
                [
                    "SOMETOOL_OVERRIDE", "SOMETOOL_ADVANCED"
                ]
            }
        ]
    }

In this example, the ``PATH`` variable is modified as before to allow
PowerShell to find the executable.  A directory has been added to the *end* of
the ``PYTHONPATH`` variable (note the explicit ``;`` because this is a simple
text operation), and some SomeTool-specific variables have been set and
deleted to get the desired environment.  ``prepend`` works in the same
manner as ``append`` but the specified content is added to the front of the
variable instead of the back.  It is also a simple text operation, hence the
above would have to change to the following to get the semicolon in the correct
place.

.. code:: JSON


    {
        "SomeTool":
        [
            {
                "prepend":
                {
                    "PYTHONPATH": "C:\\SomeTool\\PyBin;"
                }
            }
        ]
    }

Using legacy batch files
------------------------

Some tools (such as Microsoft Visual Studio) provide a traditional CMD batch
file to configure a command line environment.  Unfortunately these no longer
work with PowerShell, however the ``defer`` option for PsEnv can be used to
execute them in a child environment that can be inspected to update the current
session (see `credits`_ for more information).  For example, the following
configuration would allow a user to use the MSVC10 toolchain in a PowerShell
session:

.. code:: JSON

    {
        "msvc10":
        [
            {
                "defer":
                [
                    "C:\\Program Files (x86)\\Microsoft Visual Studio 10.0\\VC\\vcvarsall.bat"
                ]
            }
        ]
    }

Invoking ``Use-Tool msvc10`` would execute the standard ``vcvarsall.bat`` file
and merge the two environments together.  However, ``vcvarsall`` can accept a
command line parameter to select the toolchain required.  There are several
approaches to dealing with this issue, but first we'll discuss ``-DeferredArgs``.  It
accepts a comma-delimited set of arguments to pass directly onto the batch file:

.. code:: PowerShell

    Use-Tool -ToolName msvc10 -DeferredArgs amd64

Any legacy batch files can be given arguments using this method, but what if
there are parameters that should always be specified?  Notice that the
``defer`` is an array of strings; a command string is formed by joining every
element of a ``defer`` array together with a space and optionally escaping
arguments that contain a space.  ``-DeferredArgs`` are then joined onto the
back of this string to form the full command that is issued.  For Example:

.. code:: JSON

    {
        "msvc10":
        [
            {
                "defer":
                [
                    "C:\\Program Files (x86)\\Microsoft Visual Studio 10.0\\VC\\vcvarsall.bat",
                    "amd64"
                ]
            }
        ]
    }

Would result in ``Use-Tool msvc10`` issuing the following command (notice the
double quotes to include spaces in the filename)::

    "C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" amd64

We can refine this further using tool specs:

.. code:: JSON

    {
        "msvc10":
        [
            {
                "name": "amd64",
                "defer":
                [
                    "C:\\Program Files (x86)\\Microsoft Visual Studio 10.0\\VC\\vcvarsall.bat",
                    "amd64"
                ]
            },
            {
                "name": "x86",
                "defer":
                [
                    "C:\\Program Files (x86)\\Microsoft Visual Studio 10.0\\VC\\vcvarsall.bat",
                    "x86"
                ]
            }
        ]
    }

With the default invocation of ``vcvarsall``, the 32 bit toolchain is added to
the system ``PATH``.  But with the above tool spec, ``Use-Tool msvc10`` will
load the 64 bit tool chain by default and the 32 bit version if ``Use-Tool
msvc10 x86`` is issued.


Testing
=======

A set of unit-tests have been provided in the ``Test`` directory.  To run them,
`PSUnit <http://psunit.codeplex.com/>`_ must be installed and on the system
``PATH``.  Open ``Test\PsEnv.Test.ps1`` in PowerShell ISE, ``cd`` into the
``Test`` directory and then run the tests using the *Execute Unit Tests* option
under the *PSUnit* sub-menu of the *Add-ons* menu.


Credits
=======

Deferred environment modifications (i.e., support for legacy batch files) is
based on `Robert Anderson <http://rwandering.net/>`_'s clever solution for
`replacing the Visual Studio command prompt with PowerShell`__.

.. __: http://rwandering.net/2006/05/02/vs2005-powershell-prompt/


Licence
=======

This tool is covered by the MIT licence.
