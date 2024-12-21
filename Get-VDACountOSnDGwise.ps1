#Author - Kamlesh Vishwakerma (Citrix and Azure Architect)
#Get the Single Session VDA count, per Delivery Group by OS Type.

Clear-Host
[DateTime]::Now
#$logonDate = (Get-Date).AddDays(-30)
$VDIMachines = Get-BrokerMachine -MaxRecordCount 5000 -SessionSupport SingleSession
Write-Host "Total VDI Count: $($VDIMachines.Count)" -ForegroundColor Green

# Initialize counts for Delivery Group and OS Type
$DeliveryGroupCounts = @{}
$OSTypeCounts = @{}

foreach ($machine in $VDIMachines) {
    # Get OS Type and Delivery Group
    $osType = $machine.OSType
    $deliveryGroup = $machine.DesktopGroupName
    
    # Ensure valid OS Type and Delivery Group
    if (![string]::IsNullOrWhiteSpace($osType)) {
        if ($OSTypeCounts.ContainsKey($osType)) {
            $OSTypeCounts[$osType]++
        } else {
            $OSTypeCounts[$osType] = 1
        }
    }
    
if (![string]::IsNullOrWhiteSpace($deliveryGroup)) {
    # Check if Delivery Group matches the specific groups
    # Performance Windows 10 VDI, Performance Windows 11 VDI, Standard Windows 10 VDI and Standard Windows 11 VDI are the names of the delivery groups.
    # Replace these by the name of DGs, you want to use.

    if ($deliveryGroup -match "Performance Windows 11 VDI") {
        $DeliveryGroupCounts["Performance Windows 11 VDI"]++
    } elseif ($deliveryGroup -match "Standard Windows 11 VDI") {
        $DeliveryGroupCounts["Standard Windows 11 VDI"]++
    } elseif ($deliveryGroup -match "Performance Windows 10 VDI") {
        $DeliveryGroupCounts["Performance Windows 10 VDI"]++
    } elseif ($deliveryGroup -match "Standard Windows 10 VDI") {
        $DeliveryGroupCounts["Standard Windows 10 VDI"]++
    } else {
        # Optional: Handle unmatched delivery groups
        $DeliveryGroupCounts["Other"]++
    }
}

}

# Display OS Type counts
Write-Host "OS Type Counts:" -ForegroundColor Green
foreach ($osType in $OSTypeCounts.Keys) {
    Write-Host "$osType -  $($OSTypeCounts[$osType])" -ForegroundColor Cyan
}

# Display Delivery Group counts
Write-Host "Delivery Group Counts (Standard/Performance):" -ForegroundColor Green
foreach ($groupType in $DeliveryGroupCounts.Keys) {
    Write-Host "$groupType -  $($DeliveryGroupCounts[$groupType])" -ForegroundColor Cyan 
}

Write-Host "Available Free Pool" -ForegroundColor Green
$StandardFreePool = Get-BrokerMachine -SessionSupport SingleSession -MaxRecordCount 5000 -DesktopGroupName "*Standard Windows 11 VDI*" -IsAssigned $false |Measure-Object 
$PerformanceFreePool = Get-BrokerMachine -SessionSupport SingleSession -MaxRecordCount 5000 -DesktopGroupName "*Performance Windows 11 VDI*" -IsAssigned $false |Measure-Object 
Write-Host "Standard Free Pool Count:" $StandardFreePool.Count -ForegroundColor Cyan
Write-Host "Performance Free Pool Count:" $PerformanceFreePool.Count -ForegroundColor Cyan

