#Author - Kamlesh Vishwakerma (Citrix and Azure Architect)

#Retrieve Users assigned to mentioned VDIs
#Input - A text file with the list of VDIs.
#Output - A csv files containing Users, assigned to the mentioned VDIs.

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

# Define the path for the VDI list
$VDIFile = "location of input text file"

# Create an array to store the data
$ReportData = @()

# Loop through each user in the user list
foreach ($VDI in Get-Content $VDIFile) {
    Write-Host "Fetching data for VDI: $VDI"
    
    # Get information from Citrix
    $Machines = Get-BrokerMachine -MaxRecordCount 5000 -SessionSupport SingleSession | Where-Object {($_.MachineName -match $VDI)} | Select-Object MachineName, AssociatedUserNames, AssociatedUserUPNs, DesktopGroupName

    # Add data to the report array
foreach ($Machine in $Machines) {
    $AssociatedUserNames = $Machine.AssociatedUserNames -join ', '  # Join the usernames into a single string
    $AssociatedUserUPNs = $Machine.AssociatedUserUPNs -join ', '   # Join UPNs into a single string

    $ReportData += [PSCustomObject]@{
        MachineName         = $Machine.MachineName
        AssociatedUserNames = $AssociatedUserNames
        AssociatedUserUPNs  = $AssociatedUserUPNs
        DesktopGroupName    = $Machine.DesktopGroupName
        
    }
}
}

# Export the report data to an Excel file
$ReportData | Export-Excel -Path $OutputFile -WorksheetName "User Report" -AutoSize -FreezeTopRow -BoldTopRow

Write-Host "Report exported to $OutputFile"

