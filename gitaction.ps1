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
                    If($($itemposx -ge $posx) -and $($itemposx -le $posxmax)){
                        If($($itemposy -ge $posy) -and $($itemposy -le $posymax)){
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
$jpgurl = $((Invoke-WebRequest 'https://www.goodberrys.com/flavor-of-the-day').images | Where-Object 'data-src' -NotMatch 'Locations').'data-src'
$uri = "https://$appname.cognitiveservices.azure.com/vision/v3.0/read/analyze?language=en"
$body = @{
    "url" = "$jpgurl"
}
$Params = @{
    uri = $uri
    method = "POST"
    contenttype ='application/json'
    headers = @{'Ocp-Apim-Subscription-Key' = $apikey}
    body = $(ConvertTo-Json $body)
    responseheadersvariable = 'response'
    statuscodevariable = 'status'
}
Invoke-RestMethod @Params
$Params = @{
    uri = "$($response.'Operation-Location')"
    method = "GET"
    headers = @{'Ocp-Apim-Subscription-Key' = $apikey}
  }
Do{
    Start-Sleep -Seconds 1
    $reply = Invoke-RestMethod @Params
}
Until($reply.status -eq 'Succeeded')
$OCR = $reply.analyzeResult.readResults.lines
#Get the Month in the OCR and find out which day the first day of the month lands on
1..-10 | ForEach-Object {
    if($OCR.Text -contains $(Get-Date (Get-Date).AddMonths($_) -UFormat %B)){
        #create object to return day value and month
        $FoM = [PSCustomObject]@{
            Date = (Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0).AddMonths($_)
            Day = Get-Date (Get-Date).AddMonths($_) -Day 1 -UFormat %u
        }
    }
}

$positions = Import-Csv .\assets\positions.csv
$flavors = Import-Csv .\assets\flavors.csv
$apikey = $env:AZURE_TOKEN
$appname = $env:AZURE_APPNAME
$Params = @{
    OCR = $OCR
    positions = $positions
    flavors = $flavors
    FoM = $FoM.Day
    Date = $FoM.Date
}
Get-Flavors @Params | ConvertTo-Json | out-file ".\$(get-date $($fom.date) -format yyyyMM)flavors.json" -Force
