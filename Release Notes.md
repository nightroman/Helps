Helps Release Notes
===================

## v1.0.4

**Breaking change**

The module *Helps* was converted into the script *Helps.ps1*. It looks like the
script module had issues. In particular, *Get-Command* called from the module
could not see some definitely available commands. In contrast, the script
*Helps.ps1* works fine in all known so far use cases.

This change is breaking but updates are easy. The script *Helps.ps1* should be
located in the path and dot-sourced. That is,

    Import-Module Helps

in old code should be replaced with

    . Helps.ps1

See *README* for more about installation and usage options.

**Other changes**

`New-Helps` generates `sets` only if there are 2+ parameter sets. It does not
output empty `parameters` entry. `links` item is generated as one line `@{...}`.

`Convert-Helps` converts tabs into 4 spaces (that is what presumably PowerShell
formatting does anyway).

## v1.0.3

Command parameters: yet missing pipeline input information is now generated.

## v1.0.2

Added *README.htm* and *Release Notes.htm*.

`Test-Helps` uses private local variables.

## v1.0.1

Converted localized files to UTF8.

## v1.0.0

New exported function `New-Helps` creates help and optional localized data
templates for commands and providers. Removed obsolete *Template-Help.ps1*.

## v1.0.0.rc4

New exported function `Merge-Helps`. It is used in order to merge the help table
of a base cmdlet with help tables of derived cmdlets. `parameters` are merged;
child `inputs`, `outputs`, `examples`, `links` are appended to the base; other
child values override base. In other words, help of derived cmdlets is derived
from base cmdlet help by Merge-Helps.

*Helps-Help.ps1* (help script of this module) uses this approach.

## v1.0.0.rc1 - v1.0.0.rc3

Overall stabilization.

## v1.0.0.rc0

The first release candidate.
