
<#
* Helps module - PowerShell help builder
* Copyright 2011 Roman Kuzmin
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
#>

### common parameters
$script:CommonParameters = @('Verbose', 'Debug', 'ErrorAction', 'ErrorVariable', 'WarningAction', 'WarningVariable', 'OutVariable', 'OutBuffer')

#.ExternalHelp Helps-Help.xml
function Convert-Helps
(
	[Parameter(Position = 0, Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string[]]$Script
	,
	[Parameter(Position = 1, Mandatory = $true)]
	[string]$Output
	,
	[Parameter(Position = 2)]
	[hashtable]$Parameters = @{}
)
{
	Set-StrictMode -Version 2
	$ErrorActionPreference = 'Stop'

	. "$PSScriptRoot\ConvertTo-MamlCommand.ps1"
	. "$PSScriptRoot\ConvertTo-MamlProvider.ps1"
	. "$PSScriptRoot\ConvertTo-Maml.ps1" (Import-Helps $Script $Parameters -Test) $Output
}

#.ExternalHelp Helps-Help.xml
function Merge-Helps
(
	[Parameter(Position = 0, Mandatory = $true)]
	[ValidateNotNull()]
	[hashtable]$First
	,
	[Parameter(Position = 1, Mandatory = $true)]
	[ValidateNotNull()]
	[hashtable]$Second
)
{
	Set-StrictMode -Version 2
	$ErrorActionPreference = 'Stop'

	# copy the first table
	$First = @{} + $First

	# join the copy with the second
	foreach($key in $Second.Keys) {
		$value1 = $First[$key]
		$value2 = $Second[$key]
		# add the second value
		if ($null -eq $value1) {
			$First[$key] = $value2
		}
		# merge parameter tables
		elseif ($key -eq 'parameters') {
			if ($value1 -isnot [hashtable]) {
				throw "Invalid 'parameters' type. Expected : Hashtable."
			}
			if ($value2 -isnot [hashtable]) {
				throw "Invalid 'parameters' type. Expected : Hashtable."
			}
			$First[$key] = $value1 + $value2
		}
		# append second arrays to the first
		elseif (('inputs', 'outputs', 'examples', 'links') -contains $key) {
			$First[$key] = @($value1) + @($value2)
		}
		# other second values override
		else {
			$First[$key] = $value2
		}
	}

	# return
	$First
}

#.ExternalHelp Helps-Help.xml
function Test-Helps
(
	[Parameter(Position = 0, Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string[]]$Script
	,
	[Parameter()]
	[hashtable]$Parameters = @{}
)
{
	Set-StrictMode -Version 2
	$ErrorActionPreference = 'Stop'

	foreach($help in (Import-Helps $Script $Parameters)) {
		$name = $help['command']
		if ($name) {
			$examples = @($help['examples'])
		}
		else {
			$name = $help['provider']
			if (!$name) {
				throw "Invalid help entry: experted 'command' or 'provider'."
			}
			$examples = @()
			$tasks = @($help['tasks'])
			foreach($task in $tasks) {
				$more = @($task['examples'])
				if ($more) {
					$examples += $more
				}
			}
		}
		if (!$examples) {
			continue
		}

		$number = 0
		foreach($example in $examples) {
			++$number
			$test = $example['test']
			if ($test) {
				if ($test -isnot [scriptblock]) {
					throw "$name : example $number : 'test' is not a script block."
				}

				$code = $example['code']
				if ($code -isnot [scriptblock]) {
					throw "$name : example $number : 'code' is not a script block."
				}

				'#'*77
				$code
				$test
				& $test $code
			}
		}
	}
}

#.ExternalHelp Helps-Help.xml
function New-Helps
(
	[Parameter(Mandatory = $true, ParameterSetName = 'Command')]
	[ValidateScript({ ($_ -is [string]) -or ($_ -is [System.Management.Automation.CommandInfo]) })]
	$Command
	,
	[Parameter(Mandatory = $true, ParameterSetName = 'Provider')]
	[ValidateScript({ ($_ -is [string]) -or ($_ -is [System.Management.Automation.ProviderInfo]) })]
	$Provider
	,
	[Parameter()]
	[string]$Indent = "`t"
	,
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$LocalizedData
)
{
	Set-StrictMode -Version 2
	$ErrorActionPreference = 'Stop'

	switch($PSCmdlet.ParameterSetName) {
		'Command' { New-HelpsCommand $Command $Indent $LocalizedData }
		'Provider' { New-HelpsProvider $Provider $Indent $LocalizedData }
	}
}

function New-HelpsCommand
(
	$Command,
	[string]$Tab,
	[string]$LocalizedData
)
{
	# resolve
	if ($Command -is [string]) {
		$commands = @(Get-Command $Command -ErrorAction 0)
		switch($commands.Count) {
			1 {
				$Command = $commands[0]
				$Name = $Command.Name
			}
			0 {
				$Name = $Command
				$Command = $null
				Write-Warning "Command is not found."
			}
			default {
				throw "There are $($commands.Count) commands."
			}
		}
	}
	else {
		$Name = $Command.Name
	}

	# info
	if ($Command) {
		$sets = @($Command.ParameterSets | Sort-Object Name)
		$parameters = @($Command.Parameters.Keys | Sort-Object)
		$outputs = @($Command.OutputType)
	}
	else {
		$sets = @()
		$parameters = @()
		$outputs = @()
	}

	$TabTab = $Tab + $Tab
	$TabTabTab = $TabTab + $Tab

	### data script
	if ($LocalizedData) {
		$data = $Tab + ($Name -replace '\W')

		''
		"# $Name command data"
		'$' + $LocalizedData + ' = @{'
		"${data}Synopsis = ''"
		"${data}Description = ''"

		foreach($set in $sets) {
			"${data}Sets$($set.Name) = ''"
		}

		foreach($parameter in $parameters) {
			if ($script:CommonParameters -notcontains $parameter) {
				"${data}Parameters$parameter = ''"
			}
		}

		"${data}InputsDescription1 = ''"

		if ($outputs) {
			foreach($type in $outputs) {
				"${data}OutputsDescription$($type.Name -replace '\W') = ''"
			}
		}
		else {
			"${data}OutputsDescription1 = ''"
		}

		"${data}Notes = ''"

		"${data}ExamplesRemarks1 = ''"

		'}'
	}

	### help script

	if ($LocalizedData) {
		$data = '$' + $LocalizedData + '.' + ($Name -replace '\W')
	}

	''
	"# $Name command help"
	'@{'

	"${Tab}command = '$Name'"

	if ($LocalizedData) {
		"${Tab}synopsis = ${data}Synopsis"
	} else {
		"${Tab}synopsis = ''"
	}

	if ($LocalizedData) {
		"${Tab}description = ${data}Description"
	}
	else {
		"${Tab}description = ''"
	}

	if ($sets) {
		"${Tab}sets = @{"
		foreach($set in $sets) {
			if ($LocalizedData) {
				"${TabTab}$($set.Name) = ${data}Sets$($set.Name)"
			}
			else {
				"${TabTab}$($set.Name) = ''"
			}
		}
		"${Tab}}"
	}

	"${Tab}parameters = @{"
	foreach($parameter in $parameters) {
		if ($script:CommonParameters -notcontains $parameter) {
			if ($LocalizedData) {
				"${TabTab}$parameter = ${data}Parameters$parameter"
			}
			else {
				"${TabTab}$parameter = ''"
			}
		}
	}
	"${Tab}}"

	"${Tab}inputs = @("
	"${TabTab}@{"
	"${TabTabTab}type = ''"

	if ($LocalizedData) {
		"${TabTabTab}description = ${data}InputsDescription1"
	}
	else {
		"${TabTabTab}description = ''"
	}

	"${TabTab}}"
	"${Tab})"

	if ($outputs) {
		"${Tab}outputs = @("
		foreach($type in $outputs) {
			"${TabTab}@{"
			"${TabTabTab}type = '$($type.Name)'"

			if ($LocalizedData) {
				"${TabTabTab}description = ${data}OutputsDescription$($type.Name -replace '\W')"
			}
			else {
				"${TabTabTab}description = ''"
			}

			"${TabTab}}"
		}
		"${Tab})"
	}
	else {
		"${Tab}outputs = @("
		"${TabTab}@{"
		"${TabTabTab}type = ''"

		if ($LocalizedData) {
			"${TabTabTab}description = ${data}OutputsDescription1"
		}
		else {
			"${TabTabTab}description = ''"
		}

		"${TabTab}}"
		"${Tab})"
	}

	if ($LocalizedData) {
		"${Tab}notes = ${data}Notes"
	}
	else {
		"${Tab}notes = ''"
	}

	"${Tab}examples = @("
	"${TabTab}@{"
	"${TabTabTab}#title = ''"
	"${TabTabTab}#introduction = ''"
	"${TabTabTab}code = {"
	"${TabTabTab}}"

	if ($LocalizedData) {
		"${TabTabTab}remarks = ${data}ExamplesRemarks1"
	}
	else {
		"${TabTabTab}remarks = ''"
	}

	"${TabTabTab}test = { . `$args[0] }"
	"${TabTab}}"
	"${Tab})"

	"${Tab}links = @("
	"${TabTab}@{"
	"${TabTabTab}text = ''"
	"${TabTabTab}URI = ''"
	"${TabTab}}"
	"${Tab})"

	'}'
}

function New-HelpsProvider
(
	$Provider,
	[string]$Tab,
	[string]$LocalizedData
)
{
	# resolve
	if ($Provider -is [string]) {
		$providers = @(Get-PSProvider $Provider -ErrorAction 0)
		switch($providers.Count) {
			1 {
				$Provider = $providers[0]
				$Name = $Provider.Name
			}
			0 {
				$Name = $Provider
				$Provider = $null
				Write-Warning "Provider is not found."
			}
			default {
				throw "There are $($providers.Count) providers."
			}
		}
	}
	else {
		$Name = $Provider.Name
	}

	# info
	if ($Provider) {
		$capabilities = $provider.Capabilities
	}
	else {
		$capabilities = ''
	}

	$TabTab = $Tab + $Tab
	$TabTabTab = $TabTab + $Tab
	$TabTabTabTab = $TabTabTab + $Tab
	$TabTabTabTabTab = $TabTabTabTab + $Tab

	### data script
	if ($LocalizedData) {
		$data = $Tab + ($Name -replace '\W')
		''
		"# $Name provider data"
		'$' + $LocalizedData + ' = @{'
		"${data}Synopsis = ''"
		"${data}Description = ''"
		"${data}TasksTitle1 = ''"
		"${data}TasksDescription1 = ''"
		"${data}TasksExamplesIntroduction1 = ''"
		"${data}TasksExamplesRemarks1 = ''"
		"${data}ParametersDescription1 = ''"
		"${data}ParametersValuesDescription1 = ''"
		'}'
	}

	### help script

	if ($LocalizedData) {
		$data = '$' + $LocalizedData + '.' + ($Name -replace '\W')
	}

	''
	"# $Name provider help"
	'@{'

	"${Tab}provider = '$Name'"
	"${Tab}drives = ''"

	if ($LocalizedData) {
		"${Tab}synopsis = ${data}Synopsis"
	}
	else {
		"${Tab}synopsis = ''"
	}

	if ($LocalizedData) {
		"${Tab}description = ${data}Description"
	}
	else {
		"${Tab}description = ''"
	}

	"${Tab}capabilities = '$capabilities'"

	"${Tab}tasks = @("
	"${TabTab}@{"
	if ($LocalizedData) {
		"${TabTabTab}title = ${data}TasksTitle1"
	}
	else {
		"${TabTabTab}title = ''"
	}
	if ($LocalizedData) {
		"${TabTabTab}description = ${data}TasksDescription1"
	}
	else {
		"${TabTabTab}description = ''"
	}

	"${TabTabTab}examples = @("
	"${TabTabTabTab}@{"
	"${TabTabTabTabTab}#title = ''"
	if ($LocalizedData) {
		"${TabTabTabTabTab}introduction = ${data}TasksExamplesIntroduction1"
	}
	else {
		"${TabTabTabTabTab}introduction = ''"
	}
	"${TabTabTabTabTab}code = {"
	"${TabTabTabTabTab}}"
	if ($LocalizedData) {
		"${TabTabTabTabTab}remarks = ${data}TasksExamplesRemarks1"
	}
	else {
		"${TabTabTabTabTab}remarks = ''"
	}
	"${TabTabTabTabTab}test = { . `$args[0] }"
	"${TabTabTabTab}}"
	"${TabTabTab})"
	"${TabTab}}"
	"${Tab})"

	"${Tab}parameters = @("
	"${TabTab}@{"
	"${TabTabTab}name = ''"
	"${TabTabTab}type = ''"
	if ($LocalizedData) {
		"${TabTabTab}description = ${data}ParametersDescription1"
	}
	else {
		"${TabTabTab}description = ''"
	}
	"${TabTabTab}cmdlets = ''"
	"${TabTabTab}values = @("
	"${TabTabTabTab}@{"
	"${TabTabTabTabTab}value = ''"
	if ($LocalizedData) {
		"${TabTabTabTabTab}description = ${data}ParametersValuesDescription1"
	}
	else {
		"${TabTabTabTabTab}description = ''"
	}
	"${TabTabTabTab}}"
	"${TabTabTab})"
	"${TabTab}}"
	"${Tab})"

	"${Tab}links = @("
	"${TabTab}@{"
	"${TabTabTab}text = ''"
	"${TabTabTab}URI = ''"
	"${TabTab}}"
	"${Tab})"

	'}'
}

function Import-Helps
(
	[Parameter()]
	[string[]]$Script
	,
	[Parameter()]
	[hashtable]$Parameters = @{}
	,
	[Parameter()]
	[switch]$Test
)
{
	$validCommandKeys = @( ###
		'command'
		'synopsis'
		#'copyright' -- help does not show it
		#'version' -- help does not show it
		'description'
		'sets'
		'parameters'
		'inputs'
		'outputs'
		'notes'
		'examples'
		'links'
	)

	$validProviderKeys = @( ###
		'provider'
		'drives'
		'synopsis'
		'description'
		'capabilities'
		#'filters' -- help does not show it
		'notes'
		'tasks'
		'parameters'
		'links'
	)

	foreach($_ in $Script) {
		$path = Resolve-Path -LiteralPath $_
		foreach($hash in (& $path @Parameters)) {
			if ($hash -isnot [hashtable]) {
				throw "$Script : Invalid help type. Expected : Hashtable. Actual : $($hash.GetType())."
			}
			if ($Test) {
				if ($hash['command']) {
					foreach($key in $hash.Keys) {
						if ($validCommandKeys -notcontains $key) {
							throw "Invalid help key : $key. Valid keys : $validCommandKeys."
						}
					}
				}
				elseif ($hash['provider']) {
					foreach($key in $hash.Keys) {
						if ($validProviderKeys -notcontains $key) {
							throw "Invalid help key : $key. Valid keys : $validProviderKeys."
						}
					}
				}
				else {
					throw "Expected either 'command' or 'provider' keys."
				}
			}
			$hash
		}
	}
}
