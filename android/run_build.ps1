$ErrorActionPreference = 'Stop'
$env:JAVA_HOME = 'C:\Program Files\Java\jdk-26.0.1'
$env:Path = "$env:JAVA_HOME\bin;" + $env:Path
Write-Host "JAVA_HOME=$env:JAVA_HOME"
Write-Host "java version:"
java -version
Write-Host "where java:"
where.exe java
Set-Location "C:\Users\NesarAhmad\Desktop\Imageapp\imageapp\android"
& .\gradlew.bat --console=plain clean assembleDebug --stacktrace 2>&1 | Tee-Object -FilePath "build_output.txt"
Write-Host "EXITCODE=$LASTEXITCODE"
Write-Host "OUTPUT_FILE=build_output.txt"
