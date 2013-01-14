
@{
	### Helps.ps1
	Helpsps1Synopsis = 'Helps.ps1 - PowerShell Help Builder'
	Helpsps1Description = @'
	Helps.ps1 provides functions for building PowerShell XML help files from
	help scripts and for creating help script templates for existing objects.
	Help can be created for everything that supports XML help: cmdlets,
	providers, scripts, and functions in scripts or modules.

	Help scripts are almost WYSIWYG, they look very similar to the result help.
	Still, they are PowerShell scripts and this makes a lot of useful features
	easy. One of them is building localized help files.

	On dot-sourcing the script provides the following functions:

	Convert-Helps
		Converts help source scripts into the PowerShell MAML help file.

	Merge-Helps
		Used to derive help of derived cmdlets from help of base cmdlets.

	New-Helps
		Creates help and localized data templates for commands and providers.

	Test-Helps
		Tests help example code snippets with built-in test script blocks.

	HELP SCRIPT

	The help source script returns hashtables describing command/provider help.
	The caller or the script itself should make all the commands available.

	Synopsis, description, remarks, etc. texts can be strings or string arrays.

	Each string is shown as a new line. Strings with leading tabs or spaces are
	treated as pre-formatted blocks. Other strings are formatted: sequences of
	not empty not indented lines are joined together with single spaces.

	COMMAND HELP TABLE

	Mandatory keys
		command, synopsis.

	description
		The default value is the synopsis text.

	sets
		Keys are parameter set names, values are remarks.

	parameters
		Keys are parameter names, values are remarks.

	examples ... title
		The default is generated as --- EXAMPLE N ---.

	examples ... code
		It is [ScriptBlock] or [string].
		[ScriptBlock] is called by 'test' called by Test-Helps.

	examples ... test
		It is [ScriptBlock].
		$args[0] is the example code being tested.

	PROVIDER HELP TABLE

	Provider help items are similar to command help items with same names.
	There are a few differences:

	Mandatory keys
		provider, synopsis.

	examples
		introduction and code are not joined as they are for commands.

	EXAMPLES

	Demo\Helps-Help.ps1
		The help script for Helps.ps1 and its functions.

	Demo\Test-Helps-Help.ps1
		Exhaustive example of command help sources.

	Demo\TestProvider.dll-Help.ps1
		Exhaustive example of provides help sources.
'@

	### Convert-Helps
	ConvertHelpsSynopsis = 'Converts help source scripts into the PowerShell help file.'
	ScriptParameter = 'Input help source script literal path(s).'
	OutputParameter = 'Output MAML help file (typically "ModuleName.dll-Help.xml").'
	ParametersParameter = 'Parameters to be passed in the help source scripts.'
	ConvertHelpsExampleRemarks = @'
It builds the help file "temp.xml" from the help script "Helps-Help.ps1".
'@

	### Test-Helps
	TestHelpsSynopsis = 'Tests help example code snippets with built-in test script blocks.'

	### Merge-Helps
	MergeHelpsSynopsis = 'Used to derive help of derived cmdlets from help of base cmdlets.'
	MergeHelpsFirst = 'The help to be inherited (analogue of a base class, e.g. base cmdlet).'
	MergeHelpsSecond = 'Additional help data (analogue of a child class, e.g. child cmdlet).'
	MergeHelpsNotes = @'
This command is designed for command help merge.
There are many known use cases with hierarchies of cmdlet classes.

As for providers, this merge can be implemented as well but upon request.
It is not yet known that this is actually needed.
'@
	MergeHelpsDescription = @'
This command is normally used in order to merge help tables of a base cmdlets
with help tables of derived cmdlets.

Child 'inputs', 'outputs', 'examples', 'links' are appended to the base.

Child 'parameters' values are merged with the base values.

Other child values override base values.
'@
	MergeHelpsOutputs = @'
The hashtable merged from the first and the second.
Note that input tables are not modified.
'@

	### New-Helps
	NewHelpsSynopsis = 'Creates help and localized data templates for commands and providers.'
	NewHelpsDescription = @'
This command creates a new command or provider help script template, populates
its values, and outputs the result source code.
'@
	NewHelpsSetsCommand = 'Creates a help script for a command.'
	NewHelpsSetsProvider = 'Creates a help script for a provider.'
	NewHelpsParametersCommand = 'The command name or object to create a help script for.'
	NewHelpsParametersProvider = 'The provider name or object to create a help script for.'
	NewHelpsParametersIndent = 'The string used for code indentation. The default is "`t".'
	NewHelpsParametersLocalizedData = @'
Tells to create the code with references to localized data and provides the
name of localized data variable. The initial localized data structure
(Hashtable with generated keys and empty string values) is also created.
'@
	NewHelpsOutputsDescription = 'Lines of the created help script.'
	NewHelpsExamplesRemarks = @'
Creates a help script for the New-Helps command with localized data to be
accessed through $data and outputs the code to the temporary file temp.ps1.
'@
}
