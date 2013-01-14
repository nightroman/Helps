
<#
.Synopsis
	Help script for Helps.sp1 and its functions.

.Description
	This help script is used in order to build help for Helps.ps1.

	It is localized, the same source is used in order to create help for
	en-US and ru-RU cultures.

	It shows how to use Merge-Helps for help inheritance. This technique is
	normally used for cmdlet hierarchies but it works for functions as well.

	It shows built-in test snippets used to test example snippet by Test-Helps.

	For more examples of help scripts see:
	* Test-Helps-Help.ps1 - function help script
	* TestProvider.dll-Help.ps1 - provider help script

.Example
	. Helps.ps1
	Convert-Helps Helps-Help.ps1 Helps-Help.xml @{ UICulture = 'ru-RU' }
#>

param
(
	$UICulture = 'en-US'
)

Set-StrictMode -Version 2
Import-LocalizedData -BindingVariable data -UICulture $UICulture

### Base help to be inherited by all commands

$AnyHelp = @{
	inputs = @()
	links = @()
}

### Base help to be inherited by Convert-Helps and Test-Helps

$BaseHelp = Merge-Helps $AnyHelp @{
	parameters = @{
		Script = $data.ScriptParameter
		Parameters = $data.ParametersParameter
	}
	outputs = @()
}

### Helps.ps1 command help
@{
	command = 'Helps.ps1'
	synopsis = $data.Helpsps1Synopsis
	description = $data.Helpsps1Description
	parameters = @{}
	inputs = @()
	outputs = @()
	links = @(
		@{ text = 'Convert-Helps' }
		@{ text = 'Merge-Helps' }
		@{ text = 'New-Helps' }
		@{ text = 'Test-Helps' }
		@{ URI = 'https://github.com/nightroman/Helps/wiki/Command-Help-Script' }
		@{ URI = 'https://github.com/nightroman/Helps/wiki/Provider-Help-Script' }
	)
}

### Convert-Helps command (inherits base help)

Merge-Helps $BaseHelp @{
	command = 'Convert-Helps'
	synopsis = $data.ConvertHelpsSynopsis
	parameters = @{
		Output = $data.OutputParameter
	}
	examples = @(
		@{
			remarks = $data.ConvertHelpsExampleRemarks
			code = {
				. Helps.ps1
				Convert-Helps Helps-Help.ps1 temp.xml
			}
			test = {
				. $args[0]
				if (!(Test-Path temp.xml)) {
					throw "Expected temp.xml"
				}
				Remove-Item temp.xml
			}
		}
	)
	links = @(
		@{ text = 'Merge-Helps' }
		@{ text = 'New-Helps' }
	)
}

### Merge-Helps command help

Merge-Helps $AnyHelp @{
	command = 'Merge-Helps'
	synopsis = $data.MergeHelpsSynopsis
	description = $data.MergeHelpsDescription
	parameters = @{
		First = $data.MergeHelpsFirst
		Second = $data.MergeHelpsSecond
	}
	notes = $data.MergeHelpsNotes
	outputs = @{
		type = '[Hashtable]'
		description = $data.MergeHelpsOutputs
	}
	links = @(
		@{ text = 'Convert-Helps' }
		@{ text = 'New-Helps' }
	)
}

### New-Helps command help

Merge-Helps $AnyHelp @{
	command = 'New-Helps'
	synopsis = $data.NewHelpsSynopsis
	description = $data.NewHelpsDescription
	sets = @{
		Command = $data.NewHelpsSetsCommand
		Provider = $data.NewHelpsSetsProvider
	}
	parameters = @{
		Command = $data.NewHelpsParametersCommand
		Provider = $data.NewHelpsParametersProvider
		Indent = $data.NewHelpsParametersIndent
		LocalizedData = $data.NewHelpsParametersLocalizedData
	}
	outputs = @(
		@{
			type = 'System.String'
			description = $data.NewHelpsOutputsDescription
		}
	)
	examples = @(
		@{
			remarks = $data.NewHelpsExamplesRemarks
			code = {
				. Helps.ps1
				New-Helps -Command New-Helps -LocalizedData data > temp.ps1
			}
			test = {
				. $args[0]
				if (!(Test-Path temp.ps1)) {
					throw 'Expected temp.ps1'
				}
				Remove-Item temp.ps1
			}
		}
	)
	links = @(
		@{ text = 'Convert-Helps' }
		@{ text = 'Merge-Helps' }
	)
}

### Test-Helps command (inherits base help)

Merge-Helps $BaseHelp @{
	command = 'Test-Helps'
	synopsis = $data.TestHelpsSynopsis
}
