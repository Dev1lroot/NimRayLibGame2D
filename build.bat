@echo off
echo Select task:
echo 1 - Build Server
echo 2 - Build Client
echo 3 - Run Test Server (non-Nim)

set /p choice=Enter number (1-3): 

if "%choice%"=="1" (
    :buildServer
    nim c --verbosity:3 --threads:on server.nim
    if %errorlevel%==0 (
        server.exe --port:3000
    )
    echo "Press any key to re-run task"
    pause
    goto :buildServer
) else if "%choice%"=="2" (
    :buildClient
    nim c --verbosity:3 --threads:on --mm:orc -d:useMalloc client.nim
    if %errorlevel%==0 (
        client.exe --addr:127.0.0.1 --port:3000
    )
    echo "Press any key to re-run task"
    pause
    goto :buildClient
) else if "%choice%"=="3" (
    :runTestServer
    node ./server_js/server.js
    echo "Press any key to re-run task"
    pause
    goto :runTestServer
)