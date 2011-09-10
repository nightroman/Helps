Helps Release Notes
===================

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
