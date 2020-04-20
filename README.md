# Goodberys Flavor of the Day
Fun Module that I am creating to parse the Flavor of the Day calendar from the Goodberry Ice Cream Website. https://www.goodberrys.com/flavor-of-the-day

You setup the free vision api: https://azure.microsoft.com/en-us/free/

You will need both a vision api app name and your api subscription key.

On first use you will need to run Set-FotDToken 'API Key' 'Vision App Name'

Then you can run Get-FotD to find out the current Flavor of the Day.


function Get-FotDOCR{
    $url = 
    $body = {
        url = something
    }
    Invoke-RestMethod -uri "myvisionapi.microsoftest.com/vision/2.0/" -body   $body
}
function Get-FirstoftheMonthSquare{
    Param($OCR)
    #Get the Month in the OCR and find out which day the first day of the month lands on
    $dayvalue = 1..-10 | ForEach-Object {
        if($OCR -contains $(Get-Date (Get-Date).AddMonths($_) -UFormat %B)){
            Get-Date (Get-Date).AddMonths($_) -Day 1 -UFormat %u
        }
    } 
    Return $dayvalue
}
function Get-JpgUrl{
    Invoke-OCR $(Invoke-WebRequest 'https://www.goodberrys.com/flavor-of-the-day').Content.split("we can make virtually any flavor you're looking for on any day.")[1].split("<!--FOOTER WITH OPEN BLOCK FIELD-->")[0].split('<img src="')[1].split('"')[0]
}
function Invoke-OCR{
    Param($jpgurl)
    $body = @{
        'url' = $jpgurl
    }
    $Params = @{
        uri = "https://goodberryvisionapi.cognitiveservices.azure.com/vision/v2.0/read/core/asyncBatchAnalyze"
        method = "POST"
        contenttype ='application/json'
        headers = @{'Ocp-Apim-Subscription-Key' = '34103018edfb4b99acc8a73827856872'}
        body = $(ConvertTo-Json $body)
    }
    Invoke-RestMethod @Params -ResponseHeadersVariable response -StatusCodeVariable status
    if($status -match '2[0-9][0-9]'){Return $Response}else{Return "Error"}
}
function Get-OCR{
    Param($batchuri)
    Invoke-RestMethod -Uri $batchuri -Headers @{ 'Ocp-Apim-Subscription-Key' = '34103018edfb4b99acc8a73827856872' }
}
$xoffset = 136
$yoffset = 99 
$positions = Import-Csv .\positions.csv
Get-JpgUrl
$OCR = Get-FotDOCR

##GET https://goodberryvisionapi.cognitiveservices.azure.com/vision/v2.0/read/operations/4983bff9-19d1-4fff-9998-7e55ea6068f2 HTTP/1.1
##Host: goodberryvisionapi.cognitiveservices.azure.com
##HEADER##Ocp-Apim-Subscription-Key: 34103018edfb4b99acc8a73827856872


##POST https://goodberryvisionapi.cognitiveservices.azure.com/vision/v2.0/read/core/asyncBatchAnalyze HTTP/1.1
##HEADER##Ocp-Apim-Subscription-Key: 34103018edfb4b99acc8a73827856872
##{"url":"https://images.squarespace-cdn.com/content/v1/52876533e4b0e8352ed4a463/1577386957388-92DR0GGVRCCVRVFDQIT1/ke17ZwdGBToddI8pDm48kCU4uZawi-NwdLSxBnC1tvAUqsxRUqqbr1mOJYKfIPR7LoDQ9mXPOjoJoqy81S2I8N_N4V1vUb5AoIIIbLZhVYy7Mythp_T-mtop-vrsUOmeInPi9iDjx9w8K4ZfjXt2dpGGLg2dd0LpA_Npt0R8QTPy1xa8dHd45tM-rRcczZ4zm7cT0R_dexc_UL_zbpz6JQ/January+2020+Goodberry%27s+Flavor+of+the+Day+Calendar.JPG"}
