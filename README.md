# Goodberys Flavor of the Day
Fun script that I am creating to parse the Flavor of the Day calendar from the Goodberry Ice Cream Website. https://www.goodberrys.com/flavor-of-the-day

I have changed this app to instead run as a Github Action that creates a json file containing the flavor of the days listed on the calendar from the goodberry's website.

I may create a module that queries this json file but you can easily pull the flavor of the day by running one line of code in PowerShell.
```
invoke-webrequest $("https://raw.githubusercontent.com/KevinLaux/GoodberysFlavoroftheDay/master/$(get-date -format yyyyMM)flavors.json") | convertfrom-json | where date -eq (get-date -format MMddyyyy)
```

```
invoke-webrequest $("https://raw.githubusercontent.com/KevinLaux/GoodberysFlavoroftheDay/master/$(get-date -format yyyyMM)flavors.json") | convertfrom-json | where date -eq (get-date -format MMddyyyy)
```
### Want the Flavor for tomorrow? (use the following command and adjust the Add Days value)
```
invoke-webrequest $("https://raw.githubusercontent.com/KevinLaux/GoodberysFlavoroftheDay/master/$(get-date -format yyyyMM)flavors.json") | convertfrom-json | where date -eq (get-date $(get-date).AddDays(1) -format MMddyyyy)
```
### When is Peanut Butter being served this Month? (You can do a Where and do a string match to find a flavor)

```invoke-webrequest $("https://raw.githubusercontent.com/KevinLaux/GoodberysFlavoroftheDay/master/$(get-date -format yyyyMM)flavors.json") | convertfrom-json | where Flavor -match 'Peanut Butter'
```
### If you just want to pull the Json into PowerShell and work with the flavor objects you can run the following code and assign it to a variable:
```
$somevariable = invoke-webrequest $("https://raw.githubusercontent.com/KevinLaux/GoodberysFlavoroftheDay/master/$(get-date -format yyyyMM)flavors.json") | convertfrom-json
'''


