
#Authenticate to Citrix Cloud DaaS
#Authenticate and connect to Azure Subscriptions where resources are mapped

<#
.SYNOPSIS
    Retrieves the list of orphaned resources not associated with production usage in Azure.

.DESCRIPTION
    This script recursively searches through Azure resource groups and to retrieve a list of orphaned resources. 
    It then filters the files based on a specified pattern and outputs the results.

.PARAMETER Path
    The root directory path where the search will begin.

.PARAMETER Pattern
    The pattern to filter the files. For example, "*.txt" to filter text files.

.PARAMETER Recurse
    A switch parameter that indicates whether to search recursively through all subdirectories.

.EXAMPLE
    Get-Files -Path "C:\MyFolder" -Pattern "*.txt" -Recurse
    Retrieves all text files from "C:\MyFolder" and its subdirectories.

.NOTES
    Author: Kamlesh Vishwakerma
    Date: October 2023
    This script requires PowerShell 5.1 or later.
#>
# Load Citrix module
Add-PSSnapIn citrix*

# Get all Azure-related connections
$Connections = Get-ChildItem XDHyp:\Connections | Where-Object { $_.PluginId -like 'Azure*' }

# Initialize a collection for the results
$Results = @()

# Iterate through each connection and collect orphaned resources
foreach ($Connection in $Connections) {
    $OrphanedResources = Get-ProvOrphanedResource -HypervisorConnectionUid $Connection.HypervisorConnectionUid

    # Add the results to the collection with connection information
    foreach ($Resource in $OrphanedResources) {
        $Results += [PSCustomObject]@{
            ConnectionName = $Connection.PSChildName
            ResourceType   = $Resource.ResourceType
            ResourceName   = $Resource.Id
        }
    }
}

# Export results to a CSV file
$today = Get-Date -Format FileDate
$OutputFile = "C:\Temp\OrphanedResources-$today.csv"  # Specify the output file path
$Results | Export-Csv -Path $OutputFile -NoTypeInformation

Write-Output "Results saved to $OutputFile"

Start-Sleep 180
#Excel formatting

# Import required module for Excel manipulation
Import-Module ImportExcel

# Define the input and output file paths
$today = Get-Date -Format FileDate
$inputFilePath = "C:\Temp\OrphanedResources-$today.csv" # Specify the input file path
$outputFilePath = "C:\Temp\OrphanedResources-Processed-$today.xlsx" # Specify the output file path

# Load the CSV file
$data = Import-Csv -Path $inputFilePath


# Split the "ResourceName" column by delimiter "/" into multiple parts
$data1 = $data | ForEach-Object {
    $resourceParts = $_.ResourceName -split '/'
    [PSCustomObject]@{
        #ConnectionName  = $_.ConnectionName
        #ResourceName    = $Results.ResourceName
        ResourceName_1  = $resourceParts[8]
    }
}

# Further split the "ResourceName_1" column by delimiter "-" into additional parts
$data2 = $data1 | ForEach-Object {
    $subParts = $_.ResourceName_1 -split '-'
    [PSCustomObject]@{
        #ConnectionName   = $_.ConnectionName
        #ResourceName     = $Results.ResourceName
        ResourceName_1_1 = $subParts[0]
    }
}

# Export the transformed data to an Excel file
$data2 | Export-Excel -Path $outputFilePath -WorksheetName 'ProcessedData' -AutoSize
Write-Output "Formatted List of VMs saved to $outputFilePath"

Start-Sleep 60
##Check if the machines are available in Citrix, filtered by VDI

# Run the initial script and capture the output
foreach ($Machine in $data2.ResourceName_1_1) {
    Get-BrokerMachine -MachineName *$Machine* | Select-Object -ExpandProperty MachineName
}

Start-Sleep 60

foreach ($Machine in $data2.ResourceName_1_1) 
{
    $output = Get-BrokerMachine -MachineName *$Machine* | Select-Object -ExpandProperty MachineName
        # Check if the output is non-empty
            if ($output) 
            {
        # Output exists, run Script 1
                Write-Output "Running Script 1..."
                #$resourceIds = $data.ResourceName
                $tagName = "CitrixDetectIgnore"
                $tagValue = "true"
                $uresourceIds = $data.ResourceName | Where-Object { $_ -match $Machine }
                    
                foreach ($uresourceID in $uresourceIds)
                {
                Update-AzTag -ResourceId $uresourceId -Tag @{$tagName=$tagValue} -Operation Merge
                Write-Output "Tagging: $uresourceID"
                Write-Verbose "Processing Machine: $Machine"
                }
            }
            ###############################################
            #Delete or Ignore the resources
    
            else {
                # Output is empty, run Script 2
                  Write-Output "Running Script 2..."
   
                try {
                       #$id = $row.id
                       $dresourceIds = $data.ResourceName | Where-Object { $_ -match $Machine }
                        foreach ($dresourceID in $dresourceIds)
                            {
                            #Write-Output ("Resource Id: " + $dresourceID)
                            Remove-AzResource -ResourceId $dresourceID # Remove the resource
                            Write-Output "Removing Resource ID: $dresourceID"
                            }
                     } 
                catch {
                        Write-Output "Failed to remove resource: $dresourceID"
                        Write-Host $_.Exception.Message
                      }

                    }
}
#===================End Of Script=============================================
