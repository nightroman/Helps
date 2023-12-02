# PowerShell Help Builder

Helps.ps1 provides functions for building PowerShell XML help files from help
scripts and for creating help script templates for existing objects. Help may
be created for everything that supports XML help: cmdlets, providers, scripts,
and functions in scripts or modules.

Help scripts are similar to the result help and they are easier to compose than
XML. Scripts make a lot of things easy. One of them is building localized help.

## Quick Start

**Step 1:**
Helps is distributed as the NuGet package [Helps](https://www.nuget.org/packages/Helps).
Download it by NuGet tools or [directly](http://nuget.org/api/v2/package/Helps).
In the latter case save it as *".zip"* and unzip. Use the package subdirectory
*"tools"*. Consider adding this directory to the path.

**Step 2:**
Choose the command, for example *My-Command* cmdlet from *MyModule*, and make
the command available, i.e. import the module. If *My-Command* is a script
function then dot-source the script.

    Import-Module MyModule

**Step 3:**
Dot-source the script *Helps.ps1*. This command loads its utility functions
into the current scope, the global scope if it is called from the command
line:

    . Helps.ps1

**Step 4:**
Create and copy/save the template help script of *My-Command*, paste/open the
script in an editor and fill the empty placeholders it with proper content.

    New-Helps -Command My-Command
    New-Helps -Command My-Command | Set-Clipboard
    New-Helps -Command My-Command > MyModule.dll-Help.ps1

**Step 5:**
Build the XML help *Module.dll-Help.xml* from the help script. Copy the result
to the module/script directory or a culture resource subdirectory, say,
*en-US*.

    Convert-Helps MyModule.dll-Help.ps1 MyModule.dll-Help.xml

This is it. In a new PowerShell session import the command's module or
dot-source the command's script and get the command help:

    Import MyModule
    Get-Help My-Command

## How To Get Help

Make sure *Helps-Help.xml* is in the same directory with *Helps.ps1* or in a
culture resource subdirectory (like *en-US* or *ru-RU* in the package).

For *Helps.ps1*. Assuming it is in the path:

    help Helps.ps1

For its functions. At first dot-source the script and then call `help`:

    . Helps.ps1
    help Convert-Helps -Full
    help New-Helps -Full
    ...

## See Also

* [Command Help Script](https://github.com/nightroman/Helps/wiki/Command-Help-Script)
* [Provider Help Script](https://github.com/nightroman/Helps/wiki/Provider-Help-Script)
* [Localized Help Script](https://github.com/nightroman/Helps/wiki/Localized-Help-Script)
* [Help Scripts in Projects](https://github.com/nightroman/Helps/wiki/Help-Scripts-in-Projects)
* [Why Helps is not a module](https://github.com/nightroman/Helps/issues/9)
