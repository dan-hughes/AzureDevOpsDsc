<#
    .SYNOPSIS
        Peforms test on a provided 'ResourceId' to provide a boolean ($true or $false)
        return value. Returns $true if the test is successful.

        NOTE: Use of the '-IsValid' switch is required.

    .PARAMETER ResourceId
        The 'ResourceId' to be tested/validated.

    .PARAMETER IsValid
        Use of this switch will validate the format of the 'ResourceId'
        rather than the existence/presence of it.

        Failure to use this switch will throw an exception.

    .EXAMPLE
        Test-AzDevOpsApiResourceId -ResourceId 'YourResourceIdHere' -IsValid

        Returns $true if the 'ResourceId' provided is of a valid format.
        Returns $false if it is not.
#>
function Test-AzDevOpsApiResourceId
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceId,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SwitchParameter]
        $IsValid
    )

    if (!$IsValid)
    {
        $errorMessage = $script:localizedData.MandatoryIsValidSwitchNotUsed -f $MyInvocation.MyCommand
        New-InvalidOperationException -Message $errorMessage
    }


    if (![guid]::TryParse($ResourceId, $([ref][guid]::Empty)))
    {
        return $false
    }


    return $true
}