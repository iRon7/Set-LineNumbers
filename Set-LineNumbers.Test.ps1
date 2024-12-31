#Requires -Modules @{ModuleName="Pester"; ModuleVersion="5.5.0"}

Using Namespace System.Collections

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'False positive')]
param ()

Set-Alias -Name Sort-Topological -Value .\Sort-Topological.ps1

BeforeAll {

   Set-StrictMode -Version Latest
}

Describe 'Set-LineNumbers' {

    BeforeAll {

        $Script = @'
function CountChar([String]$Text, [Char]$Char) {
    $Text.ToCharArray() | Where-Object { $_ -eq $Char } | Measure-Object | Select-Object -ExpandProperty Count
}

$Text = @"
Finished files are the result of years
of scientific study combined with the
experience of many years.
"@
CountChar -Text $Text -Char 'f'
'@
        $Expected = Invoke-Expression $Script
    }

    Context 'Existence Check' {

        It 'Help' {
            .\Set-LineNumbers.ps1 -? | Out-String -Stream | Should -Contain SYNOPSIS
        }
    }

    Context 'Basic' {

        It 'Adding line numbers' {

            $Numbered = $Script | .\Set-LineNumbers.ps1
            { Invoke-Expression $Numbered } | Should -not -throw
            Invoke-Expression $Numbered | Should -be $Expected
            $Numbered | Should -Be @'
<# 01 #> function CountChar([String]$Text, [Char]$Char) {
<# 02 #>     $Text.ToCharArray() | Where-Object { $_ -eq $Char } | Measure-Object | Select-Object -ExpandProperty Count
<# 03 #> }
<# 04 #>
<# 05 #> $Text = @"
Finished files are the result of years
of scientific study combined with the
experience of many years.
"@
<# 10 #> CountChar -Text $Text -Char 'f'
'@
        }

        It 'Updating line numbers' {

            $Numbered = $Script | .\Set-LineNumbers.ps1
            "# Count the F's", $Numbered | .\Set-LineNumbers.ps1 | Should -Be @'
<# 01 #> # Count the F's
<# 02 #> function CountChar([String]$Text, [Char]$Char) {
<# 03 #>     $Text.ToCharArray() | Where-Object { $_ -eq $Char } | Measure-Object | Select-Object -ExpandProperty Count
<# 04 #> }
<# 05 #>
<# 06 #> $Text = @"
Finished files are the result of years
of scientific study combined with the
experience of many years.
"@
<# 11 #> CountChar -Text $Text -Char 'f'
'@
        }

        It 'Removing line numbers' {

            $Numbered  = $Script | .\Set-LineNumbers.ps1
            $Numbered | .\Set-LineNumbers.ps1 -Remove | Should -Be $Script
        }
    }

}