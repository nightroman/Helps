
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

<#
.Synopsis
	Converts command help to MAML.
	It is not designed for direct calls.
#>
function ConvertTo-MamlCommand
(
	[Parameter(Mandatory = $true)]
	$Help
)
{
	$script:Name = $Help.command
	if ($script:Name -match '^(\w+)-(\w+)$') {
		$verb = $matches[1]
		$noun = $matches[2]
	}
	else {
		$verb = $null
		$noun = $null
	}

	$script:Command = Get-Command $script:Name

	# check command type
	if ($script:CommandType) {
		if (($script:CommandType -eq 'Cmdlet') -and ($script:Command.CommandType -ne 'Cmdlet')) {
			throw @'
Function/cmdlet help cannot share a cmdlet/function help file:
http://blogs.msdn.com/b/powershell/archive/2009/07/09/function-help-cannot-share-a-cmdlet-help-file.aspx
'@
		}
	}
	else {
		$script:CommandType = $script:Command.CommandType
	}

	### command
	@'
<command:command xmlns:maml="http://schemas.microsoft.com/maml/2004/10" xmlns:command="http://schemas.microsoft.com/maml/dev/command/2004/10" xmlns:dev="http://schemas.microsoft.com/maml/dev/2004/10">
<command:details>
'@

	@"
<command:name>$script:Name</command:name>
"@

	### synopsis

	$synopsis = @($Help.synopsis)
	if (!$synopsis) {
		throw "$script:Name : Synopsis should not be empty."
	}

	Out-Text maml:description maml:para $synopsis

	### copyright -- help does not show it

	### verb/noun
	if ($verb) {
		@"
<command:verb>$verb</command:verb>
<command:noun>$noun</command:noun>
"@
	}

	### version -- help does not show it

	@'
</command:details>
'@

	### description & sets

	$description = @($Help['description'])
	if (!$description) {
		$description = @($synopsis)
	}

	$sets = $Help['sets']
	if ($sets) {
		if ($sets -isnot [Hashtable]) {
			throw "$script:Name : Invalid 'sets' type. Expected : Hashtable. Actual : $($sets.GetType())."
		}
		$sets = @{} + $sets
		foreach($set in Get-ParameterSet) {
			$remarks = $sets[$set.Name]
			$sets.Remove($set.Name)
			if ($remarks) {
				$description += ''
				$description += "> $script:Name " + (Get-ParameterSetParameter $set $sortParameterInSyntax | .{process{
					if ($_.IsMandatory) {
						"-$($_.Name)"
					}
					else {
						"[-$($_.Name)]"
					}
				}})
				$description += $remarks
			}
		}
		if ($sets.Count) {
			throw "$script:Name : Invalid parameter set names : $($sets.Keys)"
		}
	}

	Out-Text maml:description maml:para $description

	### syntax (generated)

	'<command:syntax>'

	foreach($set in Get-ParameterSet) {
		'<command:syntaxItem>'
		"<maml:name>$script:Name</maml:name>"
		$set.Parameters | Sort-Object $sortParameterInSyntax | .{process{ if ($script:CommonParameters -notcontains $_.Name) {
			$start = '<command:parameter '
			if ($_.IsMandatory) { $start += 'required="true" ' } else { $start += 'required="false" ' }
			if ($_.Position -ge 0) { $start += 'position="' + ($_.Position + 1) + '" ' } else { $start += 'position="named" ' }
			$start += '>'
			$start
			"<maml:name>$($_.Name)</maml:name>"
			if ($_.ParameterType -ne [System.Management.Automation.SwitchParameter]) { #??? variableLength="false"
				@"
<command:parameterValue required="true">$($_.ParameterType.Name)</command:parameterValue>
"@
			}
			'</command:parameter>'
		}}}
		'</command:syntaxItem>'
	}

	'</command:syntax>'

	### parameters

	$parameters = $Help['parameters']
	if (!$parameters) {
		throw "$script:Name : Missing mandatory 'parameters' entry."
	}
	if ($parameters -isnot [Hashtable]) {
		throw "$script:Name : Invalid 'parameters' type. Expected : Hashtable. Actual : $($parameters.GetType())."
	}
	$parameters = @{} + $parameters

	'<command:parameters>'

	Get-CommandParameter $script:Command { if ($_.Position -ge 0) { $_.Position } else { 999 } }, Name | .{process{
		$start = '<command:parameter '
		if ($_.IsMandatory) { $start += 'required="true" ' } else { $start += 'required="false" ' }
		if ($_.Position -ge 0) { $start += 'position="' + ($_.Position + 1) + '" ' } else { $start += 'position="named" ' }
		$start += '>'
		$start
		"<maml:name>$($_.Name)</maml:name>"

		$parameterDescription = @($parameters[$_.Name])
		if (!$parameterDescription) {
			Write-Warning "$script:Name : missing parameter description : $($_.Name)"
		}
		if ($_.ParameterType.IsEnum) {
			$parameterDescription += 'Values : ' + ([Enum]::GetValues($_.ParameterType) -join ', ')
		}

		Out-Text maml:description maml:para $parameterDescription

		'</command:parameter>'

		$parameters.Remove($_.Name)
	}}

	if ($parameters.Count) {
		throw "$script:Name : Invalid parameter names : $($parameters.Keys)."
	}

	'</command:parameters>'

	### inputs - not yet supported type's uri, description

	$inputs = $Help['inputs']
	if ($null -eq $inputs) {
		Write-Warning "$script:Name : Missing 'inputs' entry. If it is empty then set it to @()."
	}
	else {
		$inputs = @($inputs)
		if ($inputs.Count -eq 0) {
			$inputs = , @{ type = 'None' }
		}
	}

	if ($inputs) {
		Out-Types command:inputTypes command:inputType $inputs
	}

	### outputs - not yet supported type's uri, description

	$outputs = $Help['outputs']

	$outputs = $Help['outputs']
	if ($null -eq $outputs) {
		Write-Warning "$script:Name : Missing 'outputs' entry. If it is empty then set it to @()."
	}
	else {
		$outputs = @($outputs)
		if ($outputs.Count -eq 0) {
			$outputs = , @{ type = 'None' }
		}
	}

	if ($outputs) {
		Out-Types command:returnValues command:returnValue $outputs
	}

	### notes - not standard

	$notes = @($Help['notes'])
	if ($notes) {
		'<maml:alertSet>'
		'<maml:alert>'
		Out-Line maml:para $notes
		'</maml:alert>'
		'</maml:alertSet>'
	}

	### examples

	$examples = @($Help['examples'])
	if ($examples) {
		Out-Examples $examples $script:TagsExampleCommand
	}

	### links

	$links = @($Help['links'])
	if ($links) {
		Out-Links $links $script:TagsLinksCommand
	}

	# complete command
	'</command:command>'
}
