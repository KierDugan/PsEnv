PsEnv
=====

A simple PowerShell module that allows specific tools to be added to the current
environment by updating environment variables from  JSON file.

Motivation
----------

It's surprisingly easy for the PATH variable on a development computer to
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


Commands
========

TODO: Describe `Set-PsEnvConfig` and `Use-Environment` (`use`) here.


JSON environment description format
===================================

TODO.


Example use-case
================

TODO.

