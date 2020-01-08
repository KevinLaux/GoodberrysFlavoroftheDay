#These are public functions for the Goodberry's Flavor of the Day module
Function Get-FotD {
    #much work is needed
    [CmdletBinding(DefaultParameterSetName='Date')]
    [OutputType([PSCustomObject])]
    Param
    (
    [Parameter(ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,  
        Position=0,
        ParameterSetName='Date')]
    [DateTime[]]$Dates = (Get-Date),
    [Parameter(ParameterSetName='Flavor')]
    #Would like to validate against Full Name Flavors or short names[ValidateSet($flavors)]
    [String[]]$Flavor,
    [Parameter(ParameterSetName='All')]
    [Switch]$All
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting: $($MyInvocation.Mycommand)"
        $Script:OCR = $(InvokeOCR).recognitionResults.lines
        $Script:FoMS = GetFirstoftheMonthSquare $OCR
        $Script:Flavorlist = GetFlavors $OCR $Positions $Flavors $FoMs.Day $FoMs.Date
        $return = @()
    } #begin

    Process {
        if($Date){
            foreach($D in $Dates){
                foreach($F in $Script:Flavorlist){
                    $compdate = $(get-date ($D) -Format ddMMyyyy)
                    $flavordate = $(get-date ($F.date) -Format ddMMyyyy)
                    if($compdate -eq $F){$return += $F}
                }
            }
        }
        elseif($Flavor){
            foreach($fl in $flavor){
                foreach($F in $Script:Flavorlist){
                    if($F.Flavor -match $fl){$return+=$F}
                }
            }
        }
        elseif($All){
            $return += $Script:Flavorlist
        }
        Return $return
    }
    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending: $($MyInvocation.Mycommand)"
    } #end

}
Function Set-FotDToken{
    [cmdletbinding()]
    Param(
        [Parameter(HelpMessage = "Set the FotD Token.")]
        [String]$APIparam,
        [String]$visionAppName
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting: $($MyInvocation.Mycommand)"
        $secureapikey = $APIParam #ConvertTo-SecureString -String $APIparam -AsPlainText -Force
        $script:apikey = $APIparam 
        $script:visionappname = $visionAppName
    } #begin

    Process {
        $jsonAPI = [PSCustomObject]@{
            APIKey = $secureapikey.ToString()
            VisionAppName = $visionAppName
        }
        if(!(test-path  $tokenpath)){new-item -ItemType Directory -Path $tokenpath}
        $jsonAPI | ConvertTo-Json | Out-File $tokenfile
    }
    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending: $($MyInvocation.Mycommand)"
    } #end
}