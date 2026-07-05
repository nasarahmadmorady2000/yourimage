$ErrorActionPreference = 'Stop'
Write-Host "PWD = $(Get-Location)"
Write-Host "Shell = PowerShell"
Write-Host "Listing C:\Program Files\Java"
Get-ChildItem 'C:\Program Files\Java' -Directory | ForEach-Object { Write-Host $_.FullName }
Write-Host "\nCurrent PATH:"
Write-Host $env:Path
Write-Host "\nWinget installed packages matching Temurin:"
winget list | Select-String -Pattern 'Temurin' | ForEach-Object { Write-Host $_.Line }
Write-Host "\nWinget search Temurin JDK packages:"
winget search --id EclipseAdoptium.Temurin | Select-String -Pattern 'Temurin' | ForEach-Object { Write-Host $_.Line }
