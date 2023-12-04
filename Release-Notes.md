# Helps Release Notes

## v1.2.9

Improve generic type names, e.g. `Nullable[Double]` instead of `Nullable'1`

## v1.2.8

Tweak generated help comments

## v1.2.7

master -> main

## v1.2.6

Add `ProgressAction` to common parameters (PS 7.4)

## v1.2.5

- Amend parameter set sorting by parameter count.
- Amend formatting of example script blocks.
- Use `###` comments in generated help scripts.

## v1.2.4

Sort parameter sets so that the default goes first.

## v1.2.3

Keep parameter positions as specified, do not number from 0 or 1.
PowerShell is not consistent, too, so let it be up to developers.

## v1.2.2

Replace tabs with spaces in examples defined as script blocks.

## v1.2.1

Work around missing empty lines between examples with remarks.

## v1.2.0

Resolved #8 (*required* in parameter info).

NuGet package: set `developmentDependency`.

## v1.1.5

Avoid warnings about new common parameters `InformationAction` and
`InformationVariable` in PowerShell v5.

## v1.1.4

Resolved #5 (parameter info must be validated).

## v1.1.3

Resolved #4 (*wildcard* in parameter info).

## v1.1.2

Added support for default parameter values. Example:

    # just description
    Param1 = 'Description 1.'

    # with default value
    Param2 = @{
        default = 'Default value 2.'
        description = 'Description 2.'
    }

## v1.1.1

**Ignore empty inputs/outputs**

`Convert-Helps` does not write warnings on missing inputs and outputs. Also, it
does not generate "-" if they are empty, this results in extra empty lines, not
always wanted. Some developers may prefer to have these sections with no text.

## v1.1.0

**Ignore dynamic parameters**

Dynamic parameters, if any, are ignored as if they do not exist. They may be
documented in the description, for example in a manually added text section
DYNAMIC PARAMETERS.

Otherwise, depending on a command, there are too many issues. Some commands do
not even know what names their dynamic parameters may have. They may depend on
a yet unknown context and the current context on building the help may produce
some unwanted dynamic parameters.

Excluded the directory *Demo* from the package, as not really relevant. It can
be found at the project site and downloaded with other source files, if needed.

## v1.0.9

**PS v4.0 upgrade**

Adjusted for the new common parameter *PipelineVariable*.

## v1.0.8

Fixed [#2](https://github.com/nightroman/Helps/issues/2), added a test.

## v1.0.7

Improved various errors thrown by the engine. Added tests covering some errors.

Replaced the word "None" for empty `inputs` and `outputs` (`@()`) with the
culture neutral symbol "-". If this is not suitable then do not use `@()`.

Mixed help (cmdlets and functions together) is allowed. But it still should be
avoided because there are issues in PowerShell v2.

Renamed own help file *Helps.ps1-Help.xml* files to *Helps-Help.xml*.

## v1.0.6

Adapted for PowerShell V3 CTP2.

## v1.0.4, v1.0.5

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
