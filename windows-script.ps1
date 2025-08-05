Write-Host "`n===================== Server Health & Info Report =====================`n"

# 1. Server uptime
$uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptimeSpan = (Get-Date) - $uptime
Write-Host "`n1. Uptime           : $($uptimeSpan.Days) days, $($uptimeSpan.Hours) hrs, $($uptimeSpan.Minutes) mins"

# 2. Last reboot date and time
Write-Host "2. Last Reboot      : $($uptime.ToString('yyyy-MM-dd HH:mm:ss'))"

# 3. CPU info
$cpu = Get-CimInstance Win32_Processor
$cpuLoad = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
Write-Host "3. CPU Cores        : $($cpu.NumberOfLogicalProcessors)"
Write-Host "   CPU Usage        : $($cpuLoad.Average)%"

# 4. Memory info
$mem = Get-CimInstance Win32_OperatingSystem
$totalRAMGB = [math]::Round($mem.TotalVisibleMemorySize / 1MB, 2)
$freeRAMGB = [math]::Round($mem.FreePhysicalMemory / 1MB, 2)
$usedRAMGB = $totalRAMGB - $freeRAMGB
$memUsage = [math]::Round(($usedRAMGB / $totalRAMGB) * 100, 2)
Write-Host "4. Total RAM        : $totalRAMGB GB"
Write-Host "   Used RAM         : $usedRAMGB GB ($memUsage`%)"

# 5. Total storage summary
$drives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
$totalStorage = ($drives | Measure-Object -Property Size -Sum).Sum / 1GB
$usedStorage = ($drives | Measure-Object -Property FreeSpace -Sum).Sum / 1GB
$actualUsed = $totalStorage - $usedStorage
Write-Host "5. Total Storage    : $([math]::Round($totalStorage,2)) GB"
Write-Host "   Used Storage     : $([math]::Round($actualUsed,2)) GB"

# 6. Last Patch Update Date
$lastPatch = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1
Write-Host "6. Last Patch Date: $($lastPatch.InstalledOn.ToString('yyyy-MM-dd'))"

# 7. Disk Utilization per Drive
Write-Host "7. Drive Utilization:"
foreach ($drive in $drives) {
    $total = [math]::Round($drive.Size / 1GB, 2)
    $free = [math]::Round($drive.FreeSpace / 1GB, 2)
    $used = [math]::Round($total - $free, 2)
    $usagePercent = [math]::Round(($used / $total) * 100, 2)
    Write-Host "   Drive $($drive.DeviceID): $used GB used of $total GB ($usagePercent`%)"
}

# 8. CrowdStrike Version (if installed)
$crowdStrike = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" |
    Get-ItemProperty |
    Where-Object { $_.DisplayName -like "*CrowdStrike Windows Sensor*" }

if (-not $crowdStrike) {
    $crowdStrike = Get-ChildItem "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" |
        Get-ItemProperty |
        Where-Object { $_.DisplayName -like "*CrowdStrike Windows Sensor*" }
}

if ($crowdStrike) {
    Write-Host "8. Falcon CrowdStrike endpoint protection. Version: $($crowdStrike.DisplayVersion)"
} else {
    Write-Host "8. CrowdStrike: Not Installed"
}

# 9. IIS Version (if installed)
$iis = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\InetStp" -ErrorAction SilentlyContinue
if ($iis) {
    Write-Host "9. IIS Version: $($iis.VersionString)"
} else {
    Write-Host "9. IIS: Not Installed"
}

# 10. Microsoft SSMS (if available)

# Define the filter keyword
$filter = "Microsoft SQL Server Management Studio"

# Get the list of installed programs from both 32-bit and 64-bit uninstall registry locations
$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$installedSSMS = foreach ($key in $uninstallKeys) {
    Get-ItemProperty $key -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "*$filter*" } |
    Select-Object DisplayName, DisplayVersion
}

if ($installedSSMS) {
    Write-Host "`n10. Microsoft SQL Server Management Studio versions found:`n"
    $installedSSMS | Format-Table -AutoSize
} else {
    Write-Host "10. No Microsoft SQL Server Management Studio installation found."
}

# 11. Check if FileZilla Server is installed from Programs and Features
$filezilla = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" |
    Get-ItemProperty |
    Where-Object { $_.DisplayName -like "*FileZilla Server*" }

if (-not $filezilla) {
    $filezilla = Get-ChildItem "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" |
        Get-ItemProperty |
        Where-Object { $_.DisplayName -like "*FileZilla Server*" }
}

if ($filezilla) {
    Write-Host "11. FileZilla Server Version: $($filezilla.DisplayVersion)"
} else {
    Write-Host "11. FileZilla Server is NOT installed."
}


# 12. SSL Certificate Subject Names (LocalMachine\My)
Write-Host "12. Installed SSL Certificate Subjects (LocalMachine\My):"
$certs = Get-ChildItem -Path Cert:\LocalMachine\My
if ($certs.Count -eq 0) {
    Write-Host "   No certificates found."
} else {
    foreach ($cert in $certs) {
        Write-Host "   $($cert.Subject)"
    }
}

Write-Host "=========================================================" -ForegroundColor Cyan
