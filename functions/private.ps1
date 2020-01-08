function GetFotDToken{
    if(Test-Path $tokenfile){
        $tokenjson = Get-Content $tokenfile | ConvertFrom-Json
        $script:apikey = $tokenjson.apikey
        $script:visionappname = $token.visionappname
    }
    else{
        Write-Host "You have not set and API key. If you would like to use Get-FotD you will need to configure the MS Vision API and provide and API token with Set-FotDToken"
    }

}
function InvokeOCR{
    [cmdletbinding()]
    $jpgurl = $(Invoke-WebRequest 'https://www.goodberrys.com/flavor-of-the-day').Content.split("we can make virtually any flavor you're looking for on any day.")[1].split("<!--FOOTER WITH OPEN BLOCK FIELD-->")[0].split('<img src="')[1].split('"')[0]
    $body = @{
        'url' = $jpgurl
    }
    $Params = @{
        uri = "https://" + $script:visionappname + ".cognitiveservices.azure.com/vision/v2.0/read/core/asyncBatchAnalyze"
        method = "POST"
        contenttype ='application/json'
        headers = @{'Ocp-Apim-Subscription-Key' = $apikey}
        body = $(ConvertTo-Json $body)
    }
    Invoke-RestMethod @Params -ResponseHeadersVariable response -StatusCodeVariable status
    $batchuri = $Response.'Operation-Location'.split("/") | Select-Object -Last 1
    Do{
        Start-Sleep -Seconds 1
        $reply = Invoke-RestMethod $("https://" + $visionappname + ".cognitiveservices.azure.com/vision/v2.0/read/operations/$batchuri") -Method GET -Headers @{'Ocp-Apim-Subscription-Key' = '34103018edfb4b99acc8a73827856872'}
    }
    Until($reply.status -eq 'Succeeded')
    Return $reply
}
function GetFirstoftheMonthSquare{
    [cmdletbinding()]
    Param($OCR)
    #Get the Month in the OCR and find out which day the first day of the month lands on
    1..-10 | ForEach-Object {
        if($OCR.Text -contains $(Get-Date (Get-Date).AddMonths($_) -UFormat %B)){
            #create object to return day value and month
            
            $Return = [PSCustomObject]@{
                Date = (Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0).AddMonths($_)
                Day = Get-Date (Get-Date).AddMonths($_) -Day 1 -UFormat %u
            }
            Return $Return
        }
    }
}
function GetFlavors{
    [cmdletbinding()]
    Param($OCR, $Positions, $Flavors, [Int]$FoM, $Date)
    $Flavorlist = @()
    Foreach($Position in $Positions){
        $flavor = $null
        [Int]$pos = $Position.Position
        If($pos -ge $FoM){
            Foreach($item in $OCR){
                if(!$flavor){
                    $itemposx = $item.boundingBox[0]
                    $posx = $Position.TopX
                    $posxmax = [Int]$($Position.TopX) + 136
                    $itemposy = $item.boundingBox[1]
                    $posy = $Position.TopY
                    $posymax = [Int]$($Position.TopY) + 99
                    If($($itemposx -gt $posx) -and $($itemposx -lt $posxmax)){
                        If($($itemposy -gt $posy) -and $($itemposy -lt $posymax)){
                            foreach($f in $flavors){
                                if($item.text -match [regex]$($f.short)){
                                    $flavor = $f.flavor
                                    $object = [PSCustomObject]@{
                                        Date = $Date
                                        Flavor = $Flavor
                                        Position = $Position.position
                                    }
                                    $FlavorList += $object
                                }
                            }
                            
                        }
                    }
                }
            }
            $Date = $Date.AddDays(1)
        }
    }
    $FlavorList
}
$script:tokenfile = "$env:userprofile\powershell\modules\get-fotd\token.json"
$script:tokenpath = "$env:userprofile\powershell\modules\get-fotd"
