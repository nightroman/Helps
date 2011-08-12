
# Helps Module - PowerShell Help Builder

The module builds PowerShell MAML help files from PowerShell help scripts.
Help scripts are almost WYSIWYG, they look very similar to the result help.
Still, they are just scripts and this makes a lot of useful features easy.
One of them is building PowerShell localized help files.

## Quick Start

**Step 1:** Download and unzip Helps to one of the PowerShell module
directories. See `$env:PSModulePath`:

    PS> $env:PSModulePath
    C:\Users\...\Documents\WindowsPowerShell\Modules;...

**Step 2:** Choose the command, for example *My-Command* cmdlet from *MyModule*,
and make the command available, that is load the module (or dot-source scripts
for functions):

    PS> Import-Module MyModule

**Step 3:** Import the Helps module:

    PS> Import-Module Helps

**Step 4:** Create and save the template help script of *My-Command*, open the
script in an editor and modify it (at least the synopsis should not be empty):

    PS> New-Helps -Command My-Command > MyModule.dll-Help.ps1

**Step 5:** Build the PowerShell help *Module.dll-Help.xml* from
*MyModule.dll-Help.ps1* and ensure the result is in the module directory:

    PS> Convert-Helps MyModule.dll-Help.ps1 MyModule.dll-Help.xml

That is it. In a new PowerShell session import the module and get the command
help:

    PS> Import MyModule
    PS> Get-Help My-Command

## See Also

* [Command Help Script] (https://github.com/nightroman/Helps/wiki/Command-Help-Script)
* [Provider Help Script] (https://github.com/nightroman/Helps/wiki/Provider-Help-Script)
* [Localized Help Script] (https://github.com/nightroman/Helps/wiki/Localized-Help-Script)
