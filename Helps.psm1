
<#
Copyright 2011-2017 Roman Kuzmin

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
#>

#.ExternalHelp Helps-Help.xml
function Convert-Helps(
	[Parameter(Mandatory=1)][ValidateNotNullOrEmpty()][string[]]$Script,
	[Parameter(Mandatory=1)][string]$Output,
	[hashtable]$Parameters=@{}
) {
	. $PSScriptRoot/Helps.ps1
	Convert-Helps @PSBoundParameters
}

#.ExternalHelp Helps-Help.xml
function Merge-Helps(
	[Parameter(Mandatory=1)][ValidateNotNull()][hashtable]$First,
	[Parameter(Mandatory=1)][ValidateNotNull()][hashtable]$Second
) {
	. $PSScriptRoot/Helps.ps1
	Merge-Helps @PSBoundParameters
}

#.ExternalHelp Helps-Help.xml
function Test-Helps(
	[Parameter(Position=0, Mandatory=1)][ValidateNotNullOrEmpty()][string[]]$Script,
	[hashtable]$Parameters = @{}
) {
	. $PSScriptRoot/Helps.ps1
	Test-Helps @PSBoundParameters
}

#.ExternalHelp Helps-Help.xml
function New-Helps(
	[Parameter(Position=0, Mandatory=1, ParameterSetName='Command')]
	[ValidateScript({$_ -is [string] -or $_ -is [System.Management.Automation.CommandInfo]})]
	$Command,
	[Parameter(Mandatory=1, ParameterSetName='Provider')]
	[ValidateScript({$_ -is [string] -or $_ -is [System.Management.Automation.ProviderInfo]})]
	$Provider,
	[string]$Indent = "`t",
	[ValidateNotNullOrEmpty()][string]$LocalizedData
) {
	. $PSScriptRoot/Helps.ps1
	New-Helps @PSBoundParameters
}

Export-ModuleMember -Function Convert-Helps, Merge-Helps, New-Helps, Test-Helps
