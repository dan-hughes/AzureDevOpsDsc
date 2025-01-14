
# Initialize tests for module function
. $PSScriptRoot\..\..\..\..\AzureDevOpsDsc.Common.Tests.Initialization.ps1


InModuleScope 'AzureDevOpsDsc.Common' {

    $script:dscModuleName = 'AzureDevOpsDsc'
    $script:moduleVersion = $(Get-Module -Name $script:dscModuleName -ListAvailable | Select-Object -First 1).Version
    $script:subModuleName = 'AzureDevOpsDsc.Common'
    $script:subModuleBase = $(Get-Module $script:subModuleName).ModuleBase
    $script:commandName = $(Get-Item $PSCommandPath).BaseName.Replace('.Tests','')
    $script:commandScriptPath = Join-Path "$PSScriptRoot\..\..\..\..\..\..\..\" -ChildPath "output\builtModule\$($script:dscModuleName)\$($script:moduleVersion)\Modules\$($script:subModuleName)\Resources\Functions\Private\$($script:commandName).ps1"
    $script:tag = @($($script:commandName -replace '-'))

    . $script:commandScriptPath


    Describe "$script:subModuleName\Api\Function\$script:commandName" -Tag $script:tag {

        $testCasesValidPats = Get-TestCase -ScopeName 'Pat' -TestCaseName 'Valid'
        $testCasesInvalidPats = Get-TestCase -ScopeName 'Pat' -TestCaseName 'Invalid'


        Context 'When input parameters are valid' {


            Context 'When called with "Pat" parameter value and the "IsValid" switch' {


                Context 'When "Pat" parameter value is a valid "Pat"' {

                    It 'Should not throw - "<Pat>"' -TestCases $testCasesValidPats {
                        param ([System.String]$Pat)

                        { Test-AzDevOpsPat -Pat $Pat -IsValid } | Should -Not -Throw
                    }

                    It 'Should return $true - "<Pat>"' -TestCases $testCasesValidPats {
                        param ([System.String]$Pat)

                        Test-AzDevOpsPat -Pat $Pat -IsValid | Should -BeTrue
                    }
                }


                Context 'When "Pat" parameter value is an invalid "Pat"' {

                    It 'Should not throw - "<Pat>"' -TestCases $testCasesInvalidPats {
                        param ([System.String]$Pat)

                        { Test-AzDevOpsPat -Pat $Pat -IsValid } | Should -Not -Throw
                    }

                    It 'Should return $false - "<Pat>"' -TestCases $testCasesInvalidPats {
                        param ([System.String]$Pat)

                        Test-AzDevOpsPat -Pat $Pat -IsValid | Should -BeFalse
                    }
                }
            }
        }


        Context "When input parameters are invalid" {


            Context 'When called with no/null parameter values/switches' {

                It 'Should throw' {

                    { Test-AzDevOpsPat -Pat:$null -IsValid:$false } | Should -Throw
                }
            }


            Context 'When "Pat" parameter value is a valid "Pat"' {


                Context 'When called with "Pat" parameter value but a $false "IsValid" switch value' {

                    It 'Should throw - "<Pat>"' -TestCases $testCasesValidPats {
                        param ([System.String]$Pat)

                        { Test-AzDevOpsPat -Pat $Pat -IsValid:$false } | Should -Throw
                    }
                }
            }


            Context 'When "Pat" parameter value is an invalid "Pat"' {


                Context 'When called with "Pat" parameter value but a $false "IsValid" switch value' {

                    It 'Should throw - "<Pat>"' -TestCases $testCasesInvalidPats {
                        param ([System.String]$Pat)

                        { Test-AzDevOpsPat -Pat $Pat -IsValid:$false } | Should -Throw
                    }
                }
            }


        }
    }
}
