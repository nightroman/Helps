
# Helps.ps1 - PowerShell Help Builder

![BTFM](https://github.com/downloads/nightroman/Helps/BTFM.png)

*Helps.ps1* is a set of utility functions that allow to generate help script
templates and build PowerShell XML help files from PowerShell help scripts.
Help can be created for everything that supports XML help: cmdlets, providers,
standalone scripts, functions in script modules, functions in script libraries.

Help scripts are almost WYSIWYG, they look very similar to the result help.
Still, they are PowerShell scripts and this makes a lot of useful features
easy. One of them is building localized help files.

## Quick Start

**Step 1:**
An easy way to get and update the package is
[NuGet.exe Command Line](http://nuget.codeplex.com/releases):

    NuGet install Helps

Alternatively, manually download and unzip the latest package from
[Downloads](https://github.com/nightroman/Helps/downloads).

Copy *Helps.ps1* (and one of its help files *Helps.ps1-Help.xml*) to one of the
system path directories. Then the script can be dot-sourced from the command
line or scripts just by name.

    . Helps.ps1

Alternatively, *Helps.ps1* and *Helps.ps1-Help.xml* can be located anywhere,
say, in *C:/Scripts/Helps*. Then the script is dot-sourced using its path.

    . C:/Scripts/Helps/Helps.ps1

**Step 2:** Choose the command, for example *My-Command* cmdlet from
*MyModule*, and make the command available, that is load the module. If
*My-Command* is a script function then dot-source the script.

    Import-Module MyModule

**Step 3:** Dot-source the script *Helps.ps1*. This command loads its utility
functions into the current scope (the global scope if it is called from the
command line).

    . Helps.ps1

**Step 4:** Create and save the template help script of *My-Command*, open the
script in an editor and modify it (at least the synopsis should not be empty).

    New-Helps -Command My-Command > MyModule.dll-Help.ps1

**Step 5:** Build the XML help *Module.dll-Help.xml* from the help script. Copy
the result to the module/script directory or a culture resource subdirectory,
say, *en-US*.

    Convert-Helps MyModule.dll-Help.ps1 MyModule.dll-Help.xml

That is it. In a new PowerShell session import the command's module or
dot-source the command's script and get the command help:

    Import MyModule
    Get-Help My-Command

## How To Get Help

Make sure *Helps.ps1-Help.xml* is in the same directory where *Helps.ps1* is or
in an appropriate subdirectory (like *en-US* or *ru-RU* in the package).

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
