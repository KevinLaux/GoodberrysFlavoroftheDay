function Invoke-OCR{
    Param
    (
        # Token provided by VisionApp Api
        [Parameter(Mandatory=$true, Position=0)]
        $apikey,
        # Name of Vision App service created in Azure
        [Parameter(Mandatory=$true, Position=1)]
        $appname
    )
    $jpgurl = $(Invoke-WebRequest 'https://www.goodberrys.com/flavor-of-the-day').Content.split("we can make virtually any flavor you're looking for on any day.")[1].split("<!--FOOTER WITH OPEN BLOCK FIELD-->")[0].split('<img src="')[1].split('"')[0]
    $body = @{
        'url' = $jpgurl
    }
    $Params = @{
        uri = "https://" + $appname + ".cognitiveservices.azure.com/vision/v2.0/read/core/asyncBatchAnalyze"
        method = "POST"
        contenttype ='application/json'
        headers = @{'Ocp-Apim-Subscription-Key' = $apikey}
        body = $(ConvertTo-Json $body)
    }
    Invoke-RestMethod @Params -ResponseHeadersVariable response -StatusCodeVariable status
    $batchuri = $Response.'Operation-Location'.split("/") | Select-Object -Last 1
    Do{
        Start-Sleep -Seconds 1
        $reply = Invoke-RestMethod $("https://" + $appname + ".cognitiveservices.azure.com/vision/v2.0/read/operations/$batchuri") -Method GET -Headers @{'Ocp-Apim-Subscription-Key' = $apikey}
    }
    Until($reply.status -eq 'Succeeded')
    Return $reply
}
function Get-FoM{
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
function Get-Flavors{
    [cmdletbinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        $OCR,
        [Parameter(Mandatory=$true, Position=1)]
        $positions,
        [Parameter(Mandatory=$true, Position=2)]
        $flavors,
        [Parameter(Mandatory=$true, Position=3)]
        [Int]$FoM,
        [Parameter(Mandatory=$true, Position=4)]
        $Date
    )
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
                                        Date = get-date $Date -Format MMddyyy
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
$positions = Import-Csv .\assets\positions.csv
$flavors = Import-Csv .\assets\flavors.csv
$apikey = $env:API_KEY
$appname = $env:APP_Name
##Run URL parse here, determine how many months are showing Loop the rest for each month
$Params = @{
    apikey = $apikey
    appname = $appname
    #Add Param to take URL parsed from above
}
$results = (Invoke-OCR @params).recognitionResults.lines
$FoM = Get-FoM $results
$Params = @{
    OCR = $results
    positions = $positions
    flavors = $flavors
    FoM = $FoM.Day
    Date = $FoM.Date
}
Get-Flavors @Params | ConvertTo-Json | out-file ".\$(get-date $($fom.date) -format yyyyMM)flavors.json" -Force
