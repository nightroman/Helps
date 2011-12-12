
<#
.Synopsis
	Help source script for exhaustive testing of command help features.

.Description
	It is used by Test-Helps.ps1.
#>

@{
	command = 'Test-Function1' ###
	synopsis = @'
<synopsis>Synopsis is normally one line.
This line is joined.<synopsis>
'@
	description = @'
<description> Joined long line. Joined long line.
Description. Joined long line. Joined long line.

Description. Joined second long line in a new paragraph.
Description. Joined second long line in a new paragraph.<description>
'@
	sets = @{
		Set1 = @'
Description of parameter set 1.
This line is joined.
	New line. Indentation is preserved. <end>
'@
		Set2 = @(
			'Description of parameter set 2.'
			'New line.'
			'    New line. Indentation is removed. <end>'
		)
	}
	parameters = @{
		Param1 = @'
<Param1>
Paragraph 1. text text text text text text text
text text text text text text text text text text

Paragraph 2. text text text text text text text
text text text text text text text text text text
<Param1>
'@
		Param2 = @(
			@'
<Param2>
Line 1. text text text text text text text
text text text text text text text text text text
'@
			@'
Line 2. text text text text text text text
text text text text text text text text text text
<Param2>
'@
		)
		Param3 = @'
	1. Pre-formatted. The first indentation is removed from lines.
	2. This line is not joined with line 1
		3. This line is not joined with 2 and extra indentation is preserved. It is also too long; long lines should be avoided in such blocks.

	Some
		more
			text.
'@
	}
	inputs = @(
		@{
			type = '[Input1]'
			description = 'Description of the type. <end>'
		}
		@{
			type = '[Input2]'
			description = 'Description of the type.', 'New line. <end>'
		}
		@{
			type = '[Input3]'
			description = @'
Description of the type.
Joined line. <end>
'@
		}
	)
	outputs = @( #! do not copy/paste, use different names
		@{
			type = '[Output1]'
			description = 'Description of the type. <end>'
		}
		@{
			type = '[Outpu2]'
			description = 'Description of the type.', 'New line. <end>'
		}
		@{
			type = '[Outpu3]'
			description = @'
Description of the type.
Joined line. <end>
'@
		}
	)
	notes = @'
Notes. Joined long line. Joined long line.
Notes. Joined long line. Joined long line.

Notes. Joined second long line in a new paragraph.
Notes. Joined second long line in a new paragraph.
'@
	examples = @(
		@{
			#title -- omitted 'title' gets --- EXAMPLE 1, 2... ---
			introduction = 'introduction <end>'
			code = {
				$result1 = $x + $y
				$result2 = $x - $y
			}
			remarks = @'
Remarks. Joined long line. Joined long line.
Remarks. Joined long line. Joined long line.

Remarks. Joined second long line in a new paragraph.
Remarks. Joined second long line in a new paragraph.
'@
			test = {
				$x = 5
				$y = 1
				. $args[0]
				if ($result1 -ne 6) { throw }
				if ($result2 -ne 4) { throw }
				'Tested command example.'
			}
		}
		@{
			title = @'
----- Custom example title. -----

1st paragraph.
Joined line.

2nd paragraph.
Joined line.
'@
			code = @'
		<begin> Example code can be a string.
			Indented line.
		Such examples are not tested by 'test'. <end>
'@
			remarks = @(
				@'
Remarks. Joined long line. Joined long line.
Remarks. Joined long line. Joined long line.

Remarks. Joined second long line in a new paragraph.
Remarks. Joined second long line in a new paragraph.
'@,
				'This is a new string and a new line.'
			)
		}
		@{
			introduction = @'
<introduction>
Introduction is not quite flexible.

New paragraph in the same string works.
But more strings are not shown as new lines:
'@, '[We wanted this to be a new line with two trailing spaces (alas)]<introduction>  '
			code = '<code>1/0<code>'
		}
	)
	links = @(
		@{
			text = '<text>Both text<text>'
			URI = 'https://github.com/nightroman/Helps'
		}
		@{
			text = '<text>Just text<text>'
		}
		# Just URI. Note an extra leading space.
		@{
			URI = 'https://github.com/nightroman/Helps'
		}
	)
}

@{
	command = 'Test-Function2' ###
	synopsis = @(
		'Synopsis is normally one line.'
		'But many lines are possible, too.'
		''
		'This line is after the empty line.'
	)
	description = @(
		@'
Description. Joined long line. Joined long line.
Description. Joined long line. Joined long line.

Description. Joined second long line in a new paragraph.
Description. Joined second long line in a new paragraph.
'@,
		'This is a new string and a new line.'
	)
	parameters = @{}
	inputs = @()
	outputs = @()
	notes = @(
		@'
<notes>
Joined long line. Joined long line. Joined long line.
Joined long line. Joined long line. Joined long line.

Joined second long line in a new paragraph.
Joined second long line in a new paragraph.
'@,
		'This is a new string and a new line.<notes>'
	)
	examples = @{ code = '<code>Just one example<code>' }
	links = @{ text = '<text>Just one link<text>' }
}
