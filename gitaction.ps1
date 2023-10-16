function Get-FlavorsOfTheMonth {
    param (
        [string]$url
    )

    # Send a web request to the URL and store the response
    $response = Invoke-WebRequest -Uri $url

    # Parse the content of the response
    $content = $response.Content

    # Split the content into an array of events
    $events = $content -split '<article  class="tribe-events-calendar-month-mobile-events__mobile-event post-'

    # Initialize an empty array to hold the flavors of the day
    $flavorsOfTheDay = @()
    # Loop over each event
    foreach ($event in $events) {
        # Check if the event contains a 'datetime='
        if ($event -match 'datetime=') {
            # Extract the date and flavor from the event
            $date = ($event -split '<time datetime="')[1] -split '">All day' | Select-Object -First 1
            $flavor = (($date -split 'title')[2] -split '"')[1]
            $date = ($date -split '">')[0]

            # Decode HTML entities in the flavor string
            $flavor = [System.Web.HttpUtility]::HtmlDecode($flavor)

            # Add the date and flavor to the array as a custom object
            if ($date -and $flavor -and $flavor -notmatch 'season' -and $flavor -notmatch '!') {
                $flavorsOfTheDay += New-Object PSObject -Property @{
                    Date = [datetime]::ParseExact($date, 'yyyy-MM-dd', $null).ToString('MMddyyyy')
                    Flavor = $flavor
                }
            }
        }
    }

    # Remove duplicates from the array based on Date property
    $flavorsOfTheDay = $flavorsOfTheDay | Group-Object Date | ForEach-Object { $_.Group | Select-Object -First 1 }

    return $flavorsOfTheDay
}

# Define the base URL of the website
$baseUrl = "https://www.goodberrys.com/events/month/"

# Get today's date
$today = Get-Date

# Loop over each month from June 2023 to current month
for ($year = 2023; $year -le $today.Year; $year++) {
    for ($month = 6; $month -le 12; $month++) {
        if ($year -eq $today.Year -and $month -gt $today.Month) {
            break
        }

        # Construct the URL for this month
        if ($year -eq $today.Year -and $month -eq $today.Month) {
            $url = "$baseUrl"
        } else {
            $url = "$baseUrl$year-$("{0:D2}" -f $month)/"
        }

        # Construct the filename for this month's JSON file
        $filename = ".\" + $year.ToString() + ("{0:D2}" -f $month) + "Flavors.json"

        # Check if this month's JSON file already exists in the current directory
        if (!(Test-Path -Path $filename)) {
            # Get this month's flavors of the day
            try {
                Write-Output "Getting flavors for: $($url)"
                $flavorsOfTheMonth = Get-FlavorsOfTheMonth -Url "$url"

                # Convert the array to JSON
                Write-Output "Writing flavors to: $($filename)"
                ConvertTo-Json -InputObject $flavorsOfTheMonth | Set-Content -Path "$filename"
            } catch {
                Write-Output "Failed to get flavors for: $($url)"
                continue;
            }
        }
    }
}
#Consolidate Files
$year = (Get-Date).Year
$month = (Get-Date).Month
$filename = get-childitem -Path $(".\" + $year.ToString() + ("{0:D2}" -f $month) + "Flavors.json")
# Initialize an empty array to store all entries
$collection = @()

# Get all json files in the current directory
$jsonFiles = Get-ChildItem -Path .\* -Include *.json

foreach ($file in $jsonFiles) {
    # Read the content of the file and convert it from json
    $content = Get-Content $file.FullName | ConvertFrom-Json

    # Add each entry to the collection
    $collection += $content

    if($file.Name -ne $filename.Name){
        Remove-Item $file.FullName
    }
}

# Select unique entries based on the date and convert it to json
$grouped = $collection | Group-Object Date | ForEach-Object { $_.Group | Select-Object -First 1 }

# Sort the grouped collection by date in ascending order, and convert it to json
$unique = $grouped | Sort-Object Date | ConvertTo-Json

# Write the unique entries to 'allflavors.json'
$unique | Set-Content 'allflavors.json'