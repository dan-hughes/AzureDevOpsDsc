using module ..\..\..\..\output\AzureDevOpsDsc\0.2.0\Classes\AzDevOpsDscResourceBase\AzDevOpsDscResourceBase.psm1

# Initialize tests for module function
. $PSScriptRoot\..\Classes.TestInitialization.ps1

InModuleScope 'AzureDevOpsDsc' {

    $script:dscModuleName = 'AzureDevOpsDsc'
    $script:moduleVersion = $(Get-Module -Name $script:dscModuleName -ListAvailable | Select-Object -First 1).Version
    $script:subModuleName = 'AzureDevOpsDsc.Common'
    $script:subModuleBase = $(Get-Module $script:subModuleName).ModuleBase
    $script:dscResourceName = Split-Path $PSScriptRoot -Leaf
    $script:commandName = $(Get-Item $PSCommandPath).BaseName.Replace('.Tests','')
    $script:commandScriptPath = Join-Path "$PSScriptRoot\..\..\..\..\" -ChildPath "output\$($script:dscModuleName)\$($script:moduleVersion)\Classes\$script:dscResourceName\$script:dscResourceName.psm1"
    $script:tag = @($($script:commandName -replace '-'))


    Describe "$script:subModuleName\Classes\AzDevOpsDscResourceBase\$script:commandName" -Tag $script:tag {


        Context 'When no "DscCurrentStateResourceObject" object returned'{

            class AzDevOpsDscResourceBaseExample : AzDevOpsDscResourceBase # Note: Ignore 'TypeNotFound' warning (it is available at runtime)
            {
                [string]$ApiUri = 'https://some.api/_apis/'
                [string]$Pat = '1234567890123456789012345678901234567890123456789012'

                [DscProperty(Key)]
                [string]$AzDevOpsDscResourceBaseExampleName = 'AzDevOpsDscResourceBaseExampleNameValue'

                [string]$AzDevOpsDscResourceBaseExampleId # = '31e71307-09b3-4d8a-b65c-5c714f64205f' # Random GUID

                [string]GetResourceName()
                {
                    return 'AzDevOpsDscResourceBaseExample'
                }

                [Hashtable]GetDscCurrentStateObjectGetParameters()
                {
                    return @{}
                }

                [PSObject]GetDscCurrentStateResourceObject([Hashtable]$GetParameters)
                {
                    return $null
                }

                [string]GetResourceFunctionName([RequiredAction]$RequiredAction)
                {
                    return 'Get-Module'
                }
                [Hashtable]GetDesiredStateParameters([Hashtable]$Current, [Hashtable]$Desired, [RequiredAction]$RequiredAction)
                {
                    return @{
                        Name = 'SomeModuleThatWillNotExist'
                    }
                }
            }

            It 'Should not throw' {
                $azDevOpsDscResourceBaseExample = [AzDevOpsDscResourceBaseExample]::new()

               {$azDevOpsDscResourceBaseExample.GetDscCurrentStateResourceObject(@{})} | Should -Not -Throw
            }
        }


        Context 'When no "DscCurrentStateResourceObject" object returned'{

            class AzDevOpsDscResourceBaseExample : AzDevOpsDscResourceBase # Note: Ignore 'TypeNotFound' warning (it is available at runtime)
            {
                [string]$ApiUri = 'https://some.api/_apis/'
                [string]$Pat = '1234567890123456789012345678901234567890123456789012'

                [DscProperty(Key)]
                [string]$AzDevOpsDscResourceBaseExampleName = 'AzDevOpsDscResourceBaseExampleNameValue'

                [string]$AzDevOpsDscResourceBaseExampleId # = '31e71307-09b3-4d8a-b65c-5c714f64205f' # Random GUID

                [string]GetResourceName()
                {
                    return 'AzDevOpsDscResourceBaseExample'
                }

                [Hashtable]GetDscCurrentStateObjectGetParameters()
                {
                    return @{}
                }

                [PSObject]GetDscCurrentStateResourceObject([Hashtable]$GetParameters)
                {
                    return [PSObject]@{
                        Ensure = 'Present'
                    }
                }

                [string]GetResourceFunctionName([RequiredAction]$RequiredAction)
                {
                    return 'Get-Module'
                }
                [Hashtable]GetDesiredStateParameters([Hashtable]$Current, [Hashtable]$Desired, [RequiredAction]$RequiredAction)
                {
                    return @{
                        Name = 'SomeModuleThatWillNotExist'
                    }
                }
            }

            It 'Should not throw' {
                $azDevOpsDscResourceBaseExample = [AzDevOpsDscResourceBaseExample]::new()

               {$azDevOpsDscResourceBaseExample.GetDscCurrentStateResourceObject(@{})} | Should -Not -Throw
            }

        }

    }
}
