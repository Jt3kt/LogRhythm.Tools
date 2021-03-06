using namespace System
using namespace System.IO
using namespace System.Collections.Generic

Function Get-LrTags {
    <#
    .SYNOPSIS
        Return a list of tags.
    .DESCRIPTION
        The Get-LrTags cmdlet returns a list of all existing case tags, 
        and can optionally be filtered for tag names containing the specified
        string. Results will be sorted alphabetically ascending, unless
        the OrderBy parameter is set to "desc".

        Note: This cmdlet does not support pagination.
    .PARAMETER Credential
        PSCredential containing an API Token in the Password field.
        Note: You can bypass the need to provide a Credential by setting
        the preference variable $LrtConfig.LogRhythm.ApiKey
        with a valid Api Token.
    .PARAMETER Name
        Filter results that have a tag name that contain the specified string value.
        Use the -Exact switch for an explicit filter.
    .PARAMETER Sort
        Sort the results in ascending (asc) or descending (desc) order.
    .PARAMETER Exact
        Only return tags that match the provided tag name exactly.
    .INPUTS
        System.String value to Name parameter.
    .OUTPUTS
        System.Object
        
        Returns one or more LogRhythm (case) tag objects.

        [LogRhythm.Tag]
        ---------------------------------------------------
        FieldName       Type                Description
        ---------------------------------------------------
        number          [System.Int32]    Tag ID
        text            [System.String]     Tag Name
        dateCreated     [System.DateTime]   Date tag created
        createdBy       [Object]            Created by [LogRhythm.User]
    .EXAMPLE
        PS C:\> Get-LrTags
        --- 
        
        number text    dateCreated                  createdBy
        ------ ----    -----------                  ---------
            9 abc     2020-06-07T12:48:45.8266667Z @{number=-100; name=LogRhythm Administrator; disabled=False}
            12 abd     2020-06-07T18:50:59.07Z      @{number=-100; name=LogRhythm Administrator; disabled=False}
            13 akf     2020-06-07T18:50:59.1566667Z @{number=-100; name=LogRhythm Administrator; disabled=False}
            6 Boxer   2020-06-06T19:24:48.4866667Z @{number=-100; name=LogRhythm Administrator; disabled=False}
            8 Boxers  2020-06-06T19:31:24.5933333Z @{number=-100; name=LogRhythm Administrator; disabled=False}
            10 first   2020-06-07T13:03:00.8533333Z @{number=-100; name=LogRhythm Administrator; disabled=False}
            14 MyTagz  2020-06-17T18:04:02.12Z      @{number=-100; name=LogRhythm Administrator; disabled=False}
            5 New2    2020-06-06T19:04:00.2133333Z @{number=-100; name=LogRhythm Administrator; disabled=False}
            4 Peaches 2020-06-06T14:38:56.71Z      @{number=-100; name=LogRhythm Administrator; disabled=False}
            11 second  2020-06-07T13:03:00.93Z      @{number=-100; name=LogRhythm Administrator; disabled=False}
            7 Sticker 2020-06-06T19:24:48.56Z      @{number=-100; name=LogRhythm Administrator; disabled=False}
    .EXAMPLE
        PS C:\> @("Testing","Malware") | Get-LrTags
        --- 

        number   text          dateCreated                   createdBy
        ------   ----          -----------                   ---------
        120      API Testing   2019-10-05T10:38:05.7133333Z  @{number=35; name=Smith, Bob; disabled=False}
        112      Testing       2019-09-20T21:36:59.34Z       @{number=35; name=Smith, Bob; disabled=False}
            5      Malware       2019-03-13T15:11:21.467Z      @{number=35; name=Smith, Bob; disabled=False}
    .EXAMPLE
        PS C:\> @("Testing","Malware") | Get-LrTags | Select-Object -ExpandProperty text
        ---

        API Testing
        Testing
        Malware
    .NOTES
        LogRhythm-API
    .LINK
        https://github.com/LogRhythm-Tools/LogRhythm.Tools
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNull()]
        [pscredential] $Credential = $LrtConfig.LogRhythm.ApiKey,


        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        
        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet('asc','desc')]
        [string] $Sort = "asc",

        
        [Parameter(Mandatory = $false, Position = 3)]
        [switch] $Exact
    )

    Begin {
        $Me = $MyInvocation.MyCommand.Name
        
        $BaseUrl = $LrtConfig.LogRhythm.CaseBaseUrl
        $Token = $Credential.GetNetworkCredential().Password

        # Enable self-signed certificates and Tls1.2
        Enable-TrustAllCertsPolicy

        # Request Headers
        $Headers = [Dictionary[string,string]]::new()
        $Headers.Add("Authorization", "Bearer $Token")
        $Headers.Add("count", 500)
        $Headers.Add("direction", $Sort)
        

        # Request Method
        $Method = $HttpMethod.Get
    }


    Process {
        # Establish General Error object Output
        $ErrorObject = [PSCustomObject]@{
            Code                  =   $null
            Error                 =   $false
            Type                  =   $null
            Note                  =   $null
            ResponseUrl           =   $null
            Tag                   =   $Name
        }

        # Request URI
        $RequestUrl = $BaseUrl + "/tags/?tag=$Name"

        # Make Request
        if ($PSEdition -eq 'Core'){
            try {
                $Response = Invoke-RestMethod $RequestUrl -Headers $Headers -Method $Method -SkipCertificateCheck
            }
            catch {
                $Err = Get-RestErrorMessage $_
                $ErrorObject.Code = $Err.statusCode
                $ErrorObject.Type = "WebException"
                $ErrorObject.Note = $Err.message
                $ErrorObject.ResponseUrl = $RequestUrl
                $ErrorObject.Error = $true
                return $ErrorObject
            }
        } else {
            try {
                $Response = Invoke-RestMethod $RequestUrl -Headers $Headers -Method $Method
            }
            catch [System.Net.WebException] {
                $Err = Get-RestErrorMessage $_
                $ErrorObject.Code = $Err.statusCode
                $ErrorObject.Type = "WebException"
                $ErrorObject.Note = $Err.message
                $ErrorObject.ResponseUrl = $RequestUrl
                $ErrorObject.Error = $true
                return $ErrorObject
            }
        }

        # [Exact] Parameter
        # Search "Malware" normally returns both "Malware" and "Malware 2"
        if ($Exact) {
            $Pattern = "^$Name$"
            $Response | ForEach-Object {
                if($_.text -match $Pattern) {
                    return $_
                }
            }
            # No exact matches found
            return $null
        } else {
            return $Response
        }
    }


    End {
    }
}