
@{
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
	NewHelpsParametersIndent = 'The string used for code indentation.'
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
