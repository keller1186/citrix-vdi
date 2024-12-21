#Author - Kamlesh Vishwakerma (Citrix and Azure Architect)

#Retrieve all single session machines assigned to users provided in a list.
#Input - A text file with the list of users.
#Output - A csv files with all Single session assigned to the users from the input file.

#Prereq: 
# 1. Citrix Powershell SDK installed on the machine running the script from.
# 2. Login to Citrix Cloud using either Get-XdAuthentication or API Secret.


# Import the ImportExcel module if not already imported
if (-not (Get-Module -Name ImportExcel -ListAvailable)) {
    Install-Module -Name ImportExcel -Scope CurrentUser -Force
}
Import-Module ImportExcel

# Clear the console
Clear-Host

# Import Citrix module and set the Citrix session
asnp citrix*

# Define the path for the output Excel file
$OutputFile = "location of Output CSV File"

# Define the path for the user list
$UserFile = "Location of Input TXT file"

# Create an array to store the data
$ReportData = @()

# Loop through each user in the user list
foreach ($User in Get-Content $UserFile) {
    Write-Host "Fetching data for user: $User"
    
    # Get information from Citrix
    $Machines = Get-BrokerMachine -AssociatedUserUPN "$User" -SessionSupport SingleSession

    # Add data to the report array
foreach ($Machine in $Machines) {
    $AssociatedUserNames = $Machine.AssociatedUserNames -join ', '  # Join the usernames into a single string
    $AssociatedUserUPNs = $Machine.AssociatedUserUPNs -join ', '   # Join UPNs into a single string

    $ReportData += [PSCustomObject]@{
        MachineName         = $Machine.MachineName
        AssociatedUserNames = $AssociatedUserNames
        AssociatedUserUPNs  = $AssociatedUserUPNs
        DesktopGroupName    = $Machine.DesktopGroupName
        LastConnectionTime  = $Machine.LastConnectionTime
    }
}
}

# Export the report data to an Excel file
$ReportData | Export-Excel -Path $OutputFile -WorksheetName "VDI Report" -AutoSize -FreezeTopRow -BoldTopRow

Write-Host "Report exported to $OutputFile"


