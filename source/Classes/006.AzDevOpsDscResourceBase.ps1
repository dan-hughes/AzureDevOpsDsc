<#
    .SYNOPSIS
        Defines a base class from which other AzureDevOps DSC resources inherit from.
#>
class AzDevOpsDscResourceBase : AzDevOpsApiDscResourceBase
{
    [DscProperty()]
    [Ensure]
    $Ensure

    [DscProperty(NotConfigurable)]
    [Alias('result')]
    [HashTable]$LookupResult

    hidden Construct()
    {
        Import-Module AzureDevOpsDsc.Common -ArgumentList @($true)

        # Ensure that $ENV:AZDODSC_CACHE_DIRECTORY is set. If not, throw an error.
        if (-not($ENV:AZDODSC_CACHE_DIRECTORY))
        {
            Write-Verbose "[AzDevOpsDscResourceBase] The Environment Variable 'AZDODSC_CACHE_DIRECTORY' is not set."
            throw "[AzDevOpsDscResourceBase] The Environment Variable 'AZDODSC_CACHE_DIRECTORY' is not set. Please set the Environment Variable 'AZDODSC_CACHE_DIRECTORY' to the Cache Directory."
        }

        # Attempt to import the ModuleSettings.clixml file. If it does not exist, throw an error.
        $moduleSettingsPath = Join-Path -Path $ENV:AZDODSC_CACHE_DIRECTORY -ChildPath "ModuleSettings.clixml"
        Write-Verbose "[AzDevOpsDscResourceBase] Looking for ModuleSettings.clixml at path: $moduleSettingsPath"

        # Check if the ModuleSettings.clixml file exists in the Cache Directory. If not, throw an error.
        if (-not(Test-Path -Path $moduleSettingsPath))
        {
            throw "[AzDevOpsDscResourceBase] The ModuleSettings.clixml file does not exist in the Cache Directory. Please ensure that the file exists."
        }

        Write-Verbose "[AzDevOpsDscResourceBase] Found ModuleSettings.clixml file."

        # Import the ModuleSettings.clixml file
        $objectSettings = Import-Clixml -LiteralPath $moduleSettingsPath
        Write-Verbose "[AzDevOpsDscResourceBase] Successfully imported ModuleSettings.clixml."

        #
        # Import the Token information from the Cache Directory

        $organizationName = $objectSettings.OrganizationName
        $tokenObject = $objectSettings.Token
        $access_token = $tokenObject.access_token

        # Ensure that the access_token is not null or empty. If it is, throw an error.
        if ([String]::IsNullOrEmpty($access_token))
        {
            throw "[AzDevOpsDscResourceBase] The Token information does not exist in the Cache Directory. Please ensure that the Token information exists."
        }

        Write-Verbose "[AzDevOpsDscResourceBase] Access token retrieved successfully."

        #
        # Determine the type of Token (PersonalAccessToken or ManagedIdentity)

        switch ($tokenObject.tokenType.ToString())
        {
            # If the Token is empty
            { [String]::IsNullOrEmpty($_) } {
                Write-Verbose "[AzDevOpsDscResourceBase] Token type is null or empty."
                throw "[AzDevOpsDscResourceBase] The Token information does not exist in the Cache Directory. Please ensure that the Token information exists."
            }
            # If the Token is a Personal Access Token
            { $_ -eq 'PersonalAccessToken' } {
                Write-Verbose "[AzDevOpsDscResourceBase] Token type is Personal Access Token."
                New-AzDoAuthenticationProvider -OrganizationName $organizationName -SecureStringPersonalAccessToken $access_token -isResource -NoVerify
            }
            # If the Token is a Managed Identity Token
            { $_ -eq 'ManagedIdentity' } {
                Write-Verbose "[AzDevOpsDscResourceBase] Token type is Managed Identity."
                New-AzDoAuthenticationProvider -OrganizationName $organizationName -useManagedIdentity -isResource -NoVerify
            }
            # Default
            default {
                Write-Verbose "[AzDevOpsDscResourceBase] Unknown token type."
                throw "[AzDevOpsDscResourceBase] The Token information does not exist in the Cache Directory. Please ensure that the Token information exists."
            }

        }

        #
        # Initialize the cache objects. Don't delete the cache objects since they are used by other resources.

        Get-AzDoCacheObjects | ForEach-Object {
            Initialize-CacheObject -CacheType $_ -BypassFileCheck -Debug
            Write-Verbose "[AzDevOpsDscResourceBase] Initialized cache object of type: $_"
        }

    }

    hidden [Hashtable]GetDscCurrentStateObjectGetParameters()
    {
        # Setup a default set of parameters to pass into the resource/object's 'Get' method
        $getParameters = @{
            "$($this.GetResourceKeyPropertyName())" = $this.GetResourceKey()
        }

        # Append all other properties to the hashtable
        $this.GetDscResourcePropertyNames() | ForEach-Object {
            $getParameters."$_" = $this."$_"
        }

        # If there is an available 'ResourceId' value, add it to the parameters/hashtable
        if (![System.String]::IsNullOrWhiteSpace($this.GetResourceId()))
        {
            $getParameters."$($this.GetResourceIdPropertyName())" = $this.GetResourceId()
        }

        return $getParameters
    }

    hidden [PsObject]GetDscCurrentStateResourceObject([Hashtable]$GetParameters)
    {
        # Obtain the 'Get' function name for the object, then invoke it
        $thisResourceGetFunctionName = $this.GetResourceFunctionName(([RequiredAction]::Get))
        return $(& $thisResourceGetFunctionName @GetParameters)
    }

    hidden [HashTable]GetDscCurrentStateObject()
    {
        # Declare the result hashtable
        $props = @{}

        $getParameters      = $this.GetDscCurrentStateObjectGetParameters()

        # Add all properties from the current object to the hashtable
        $getParameters.Keys | ForEach-Object {
            $props."$_" = $this."$_"
        }

        $props.LookupResult = $this.GetDscCurrentStateResourceObject($getParameters)
        $props.Ensure       = $(
            if ($null -eq $props.LookupResult.Ensure)
            {
                [Ensure]::Absent
            }
            else { $props.LookupResult.Ensure }
        )
        $props.LookupResult.Ensure

        return $props

    }


    hidden [Hashtable]GetDscCurrentStateProperties()
    {
        # Obtain 'CurrentStateResourceObject' and pass into overidden function of inheriting class
        return $this.GetDscCurrentStateProperties($this.GetDscCurrentStateObject())
    }

    # This method must be overidden by inheriting class(es)
    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        # Obtain the type of $this object. Throw an exception if this is being called from the base class method.
        $thisType = $this.GetType()
        if ($thisType -eq [AzDevOpsDscResourceBase])
        {
            $errorMessage = "Method 'GetCurrentState()' in '$($thisType.Name)' must be overidden and called by an inheriting class."
            New-InvalidOperationException -Message $errorMessage
        }
        return $null
    }

    hidden [Object[]]FindEnumValuesForInteger([System.Type]$EnumType, [Int32]$Value)
    {
        [System.Collections.ArrayList]$enumValues = @()

        [System.Array]$enumValues = [System.Enum]::GetValues($EnumType)

        [System.Collections.ArrayList]$matchingEnumValues = @()

        $enumValues | ForEach-Object {
            if ($Value -band $_ -eq $_)
            {
                $matchingEnumValues.Add($_)
            }
        }

        return $matchingEnumValues.ToArray()
    }

    hidden [Hashtable]GetDscDesiredStateProperties()
    {
        [Hashtable]$dscDesiredStateProperties = @{}

        # Obtain all DSC-related properties, and add them and their values to the hashtable output
        $this.GetDscResourcePropertyNames() | ForEach-Object {
                $dscDesiredStateProperties."$_" = $this."$_"
            }

        return $dscDesiredStateProperties
    }


    hidden [RequiredAction]GetDscRequiredAction()
    {
        # Initialize required action as None
        $dscRequiredAction = [RequiredAction]::None

        # Retrieve current and desired properties
        [Hashtable]$currentProperties = $this.GetDscCurrentStateProperties()
        [Hashtable]$desiredProperties = $this.GetDscDesiredStateProperties()

        # Retrieve property names
        [System.String[]]$dscPropertyNamesWithNoSetSupport = $this.GetDscResourcePropertyNamesWithNoSetSupport()
        [System.String[]]$dscPropertyNamesToCompare = $this.GetDscResourcePropertyNames()


        switch ($desiredProperties.Ensure)
        {
            ([Ensure]::Present) {

                Write-Verbose "Desired state is Present."

                switch ($currentProperties.LookupResult.Status)
                {
                    ([DSCGetSummaryState]::NotFound) {
                        $dscRequiredAction = [RequiredAction]::New
                        Write-Verbose "Resource not found. Setting action to New."
                    }([DSCGetSummaryState]::Changed) {
                        $dscRequiredAction = [RequiredAction]::Set
                        Write-Verbose "Resource Changed. Setting action to Set."
                    }([DSCGetSummaryState]::Renamed) {
                        $dscRequiredAction = [RequiredAction]::Set
                        Write-Verbose "Resource Renamed. Setting action to Set."
                    }([DSCGetSummaryState]::Missing) {
                        $dscRequiredAction = [RequiredAction]::Remove
                        Write-Verbose "Resource missing. Setting action to Remove."
                    }([DSCGetSummaryState]::Unchanged) {
                        $dscRequiredAction = [RequiredAction]::None
                        Write-Verbose "Resource Not Changed. Setting action to Remove."
                    }
                    default {
                        $errorMessage = "Could not obtain a valid 'LookupResult.Status' value within '$($this.GetResourceName())' Test() function. Value was '$($currentProperties.LookupResult.Status)'"
                        Write-Verbose $errorMessage
                        throw (New-InvalidOperationException -Message $errorMessage)
                    }
                }

                Write-Verbose "DscActionRequired='$dscRequiredAction'"
                return $dscRequiredAction

            }

            ([Ensure]::Absent) {

                Write-Verbose "Desired state is Absent."

                $dscRequiredAction = ($currentProperties.LookupResult.Status -eq [DSCGetSummaryState]::NotFound) ? [RequiredAction]::None : [RequiredAction]::Remove

                Write-Verbose "DscActionRequired='$dscRequiredAction'"
                return $dscRequiredAction
            }

            default {
                $errorMessage = "Could not obtain a valid 'Ensure' value within '$($this.GetResourceName())' Test() function. Value was '$($desiredProperties.Ensure)'."
                Write-Verbose $errorMessage
                throw (New-InvalidOperationException -Message $errorMessage)
            }
        }

        return $dscRequiredAction
    }

    hidden [Hashtable]GetDesiredStateParameters([Hashtable]$CurrentStateProperties, [Hashtable]$DesiredStateProperties, [RequiredAction]$RequiredAction)
    {
        [Hashtable]$desiredStateParameters = $DesiredStateProperties
        [System.String]$IdPropertyName = $this.GetResourceIdPropertyName()

        # If actions required are 'None' or 'Error', return a $null value
        if ($RequiredAction -in @([RequiredAction]::None, [RequiredAction]::Error))
        {
            return $null
        }
        # If the desired state/action is to remove the resource, generate/return a minimal set of parameters required to remove the resource
        elseif ($RequiredAction -eq [RequiredAction]::Remove)
        {

            return $desiredStateParameters

        }
        # If the desired state/action is to add/new or update/set  the resource, start with the values in the $DesiredStateProperties variable, and amend
        elseif ($RequiredAction -in @([RequiredAction]::New, [RequiredAction]::Set))
        {

            # Set $desiredParameters."$IdPropertyName" to $CurrentStateProperties."$IdPropertyName" if it's known and can be recovered from existing resource
            if ([System.String]::IsNullOrWhiteSpace($desiredStateParameters."$IdPropertyName") -and
                ![System.String]::IsNullOrWhiteSpace($CurrentStateProperties."$IdPropertyName"))
            {
                $desiredStateParameters."$IdPropertyName" = $CurrentStateProperties."$IdPropertyName"
            }
            # Alternatively, if $desiredParameters."$IdPropertyName" is null/empty, remove the key (as we don't want to pass an empty/null parameter)
            elseif ([System.String]::IsNullOrWhiteSpace($desiredStateParameters."$IdPropertyName"))
            {
                $desiredStateParameters.Remove($IdPropertyName)
            }

            # Do not need/want this passing as a parameter (the action taken will determine the desired state)
            $desiredStateParameters.Remove('Ensure')

            # Add this to 'Force' subsequent function call
            $desiredStateParameters.Force = $true

            # Some DSC properties are only supported for 'New' and 'Remove' actions, but not 'Set' ones (these need to be removed)
            [System.String[]]$unsupportedForSetPropertyNames = $this.GetDscResourcePropertyNamesWithNoSetSupport()

            if ($RequiredAction -eq [RequiredAction]::Set -and
                $unsupportedForSetPropertyNames.Count -gt 0)
            {
                $unsupportedForSetPropertyNames | ForEach-Object {
                    $desiredStateParameters.Remove($_)
                }
            }

        }
        else
        {
            $errorMessage = "A required action of '$RequiredAction' has not been catered for in GetDesiredStateParameters() method."
            New-InvalidOperationException -Message $errorMessage
        }


        return $desiredStateParameters
    }


    hidden [System.Boolean]TestDesiredState()
    {
        return ($this.GetDscRequiredAction() -eq [RequiredAction]::None)
    }

    [System.Boolean] Test()
    {
        # TestDesiredState() will throw an exception in certain expected circumstances. Return $false if this occurs.
        try
        {
            return $this.TestDesiredState()
        }
        catch
        {
            return $false
        }
    }


    [Int32]GetPostSetWaitTimeMs()
    {
        return 2000
    }

    [void] SetToDesiredState()
    {
        [RequiredAction]$dscRequiredAction = $this.GetDscRequiredAction()
        $cacheProperties = $false

        if ($dscRequiredAction -in @([RequiredAction]::'New', [RequiredAction]::'Set', [RequiredAction]::'Remove'))
        {
            $dscCurrentStateProperties = $this.GetDscCurrentStateProperties()
            $dscDesiredStateProperties = $this.GetDscDesiredStateProperties()

            $dscRequiredActionFunctionName = $this.GetResourceFunctionName($dscRequiredAction)
            $dscDesiredStateParameters = $this.GetDesiredStateParameters($dscCurrentStateProperties, $dscDesiredStateProperties, $dscRequiredAction)

            # Set the lookup properties on the desired state object. Since it will be used to set the resource.
            if ($null -ne $dscCurrentStateProperties.LookupResult)
            {
                $dscDesiredStateParameters.LookupResult = $dscCurrentStateProperties.LookupResult
            }

            & $dscRequiredActionFunctionName @dscDesiredStateParameters | Out-Null
            Start-Sleep -Milliseconds $($this.GetPostSetWaitTimeMs())
        }
    }

    [void] Set()
    {
        $this.SetToDesiredState()
    }

}
