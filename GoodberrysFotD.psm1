#load functions
. $PSScriptRoot\functions\private.ps1
. $PSScriptRoot\functions\public.ps1
#load config files to help with calendarnpositioning and text interpretation
#List of positions of the top left corner of all squares on the calendar this helps to determine what text is in what square when MS sends us OCR data.
$script:positions = Import-Csv $PSScriptRoot\assets\positions.csv
#List of Flavor full names and a regex string to match on the first string provided in the MS OCR data
$script:flavors = Import-Csv $PSScriptRoot\assets\flavors.csv
#This will call the privte function to auto load the API Token
GetFotDToken
#Run FotD to announce flavor of the day on module load6