@echo off
set "JAVA_HOME=C:\Program Files\Java\jdk-17"
set "PATH=%JAVA_HOME%\bin;%PATH%"
cd /d C:\Users\NesarAhmad\Desktop\Imageapp\imageapp\android
gradlew.bat --console=plain clean assembleDebug --stacktrace --debug > build_stacktrace.txt 2>&1
type build_stacktrace.txt
echo EXITCODE=%ERRORLEVEL%
