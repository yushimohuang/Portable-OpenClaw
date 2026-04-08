@echo off
setlocal EnableDelayedExpansion

:: ========================================
:: Portable OpenClaw Onboard Script
:: ========================================
title Portable OpenClaw Onboard
color 0A

:: 获取脚本所在目录（确保相对路径正确）
set "WORK_DIR=%~dp0"
set "WORK_DIR=%WORK_DIR:~0,-1%"

echo ========================================
echo        Portable OpenClaw Onboard
echo ========================================
echo Work Directory: %WORK_DIR%
echo.

:: 1. 检查并清理残留进程
 echo [Check] Looking for existing OpenClaw processes...
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq node.exe" /fo table /nh 2^>nul ^| findstr /i "node.exe"') do (
    taskkill /F /PID %%i /T >nul 2>&1
    echo [Clean] Terminated stale node process: %%i
)
echo [Info] Waiting for processes to terminate...

:: 2. 检查 Node.js
if not exist "%WORK_DIR%\nodejs\node.exe" (
    echo [Error] Node.js not found in: %WORK_DIR%\nodejs\
    echo Please ensure nodejs folder or nodejs.zip exists
    pause
    exit /b 1
)

:: 3. 显示 Node.js 版本
for /f "tokens=*" %%i in ('"%WORK_DIR%\nodejs\node.exe" -v 2^>nul') do set NODE_VERSION=%%i
echo [Info] Node.js Version: %NODE_VERSION%
echo.

:: 4. 设置环境变量
set "PATH=%WORK_DIR%\nodejs;%PATH%"
set "NODE_PATH=%WORK_DIR%\node_modules"
set "OPENCLAW_DATA_DIR=%WORK_DIR%\data"
set "OPENCLAW_CONFIG_PATH=%OPENCLAW_DATA_DIR%\config.json"
set "OPENCLAW_CONFIG=%WORK_DIR%\data"
set "OPENCLAW_WORKSPACE=%WORK_DIR%\.openclaw\workspace"

:: 5. 创建数据目录
if not exist "%OPENCLAW_DATA_DIR%" (
    mkdir "%OPENCLAW_DATA_DIR%"
    echo [Config] Created data directory
)

:: 6. 检查 OpenClaw 核心文件
set "OPENCLAW_CLI=%WORK_DIR%\openclaw-main\openclaw.mjs"
if not exist "%OPENCLAW_CLI%" (
    set "OPENCLAW_CLI=%WORK_DIR%\node_modules\openclaw\openclaw.mjs"
    if not exist "%OPENCLAW_CLI%" (
        echo [Error] OpenClaw core not found!
        echo Please check if openclaw-main directory exists
        pause
        exit /b 1
    )
)
echo [Info] Using OpenClaw from: %OPENCLAW_CLI%
echo.

:: 7. 启动前提示
echo ========================================
echo        Starting OpenClaw Onboard...
echo ========================================
echo [Info] Running openclaw onboard command
echo [Tip] Follow the on-screen instructions
echo ========================================
echo.

:: 8. 运行 OpenClaw Onboard
 echo [Info] Running OpenClaw onboard...
:: 直接运行，避免引号嵌套问题
cd "%WORK_DIR%"
"nodejs\node.exe" "openclaw-main\openclaw.mjs" onboard

:: 9. 完成提示
echo.
echo [Info] OpenClaw onboard process completed!
echo [Info] Press any key to exit...
pause