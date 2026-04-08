@echo off
chcp 65001 >nul

:: Portable OpenClaw 修复脚本
:: 版本：1.1
:: 功能：清理旧进程、修复配置、禁用有问题的插件

echo ========================================
echo        Portable OpenClaw Fix Script
echo ========================================
echo Cleanup ^| Fix Configuration ^| Disable Plugins
echo ========================================
echo.

:: 设置工作目录
set "WORK_DIR=%~dp0"
set "DATA_DIR=%WORK_DIR%data"

:: 1. 清理旧进程
echo [Step 1] Cleaning up old OpenClaw processes...
taskkill /F /IM node.exe 2>nul
echo [Info] Old processes cleaned up

echo.

:: 2. 备份旧配置
echo [Step 2] Backing up old configuration...
if exist "%DATA_DIR%\config.json" (
    set "BACKUP_FILE=%DATA_DIR%\config.json.bak.%date:~0,4%%date:~5,2%%date:~8,2%.%time:~0,2%%time:~3,2%"
    copy "%DATA_DIR%\config.json" "%BACKUP_FILE%" >nul 2>&1
    echo [Info] Configuration backed up
)

echo.

:: 3. 创建新配置文件
echo [Step 3] Creating fixed configuration...
if not exist "%DATA_DIR%" (
    mkdir "%DATA_DIR%"
    echo [Info] Created data directory
)

:: 使用 PowerShell 创建正确的 JSON 配置
powershell -Command "$token = -join ((48..57) + (97..102) | Get-Random -Count 40 | ForEach-Object { [char]$_ }); $json = @{ meta = @{ lastTouchedVersion = '2026.3.24'; lastTouchedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ') }; commands = @{ native = 'auto'; nativeSkills = 'auto'; restart = $true; ownerDisplay = 'raw' }; gateway = @{ mode = 'local'; auth = @{ mode = 'token'; token = $token } }; channels = @{ feishu = @{ allowFrom = @('*') } }; plugins = @{ allow = @('device-pair','phone-control','talk-voice','feishu'); entries = @{ feishu = @{ enabled = $true } } } }; $json | ConvertTo-Json -Depth 5 | Out-File -FilePath '%DATA_DIR%\config.json' -Encoding UTF8 -NoNewline"

echo [Info] Created new configuration
echo.

:: 4. 清理临时文件
echo [Step 4] Cleaning up temporary files...
rmdir /s /q "%TEMP%\openclaw" 2>nul
rmdir /s /q "%LOCALAPPDATA%\Temp\openclaw" 2>nul
echo [Info] Temporary files cleaned up

echo.

:: 5. 显示新 Token
echo [Step 5] New configuration info...
echo ========================================
echo   New Token:
powershell -Command "$config = Get-Content '%DATA_DIR%\config.json' | ConvertFrom-Json; $config.gateway.auth.token"
echo ========================================

echo.

:: 6. 显示完成信息
echo ========================================
echo        Fix Completed!
echo ========================================
echo [Info] What was fixed:
echo [Info] 1. Killed old OpenClaw processes
echo [Info] 2. Backed up old configuration
echo [Info] 3. Created new configuration with:
echo [Info]    - gateway.mode = local
echo [Info]    - plugins.allow = device-pair, phone-control, talk-voice, feishu
echo [Info]    - plugins.entries = feishu enabled
echo [Info] 4. Cleaned up temporary files
echo.
echo [Next Steps]
echo 1. Run 一键启动.bat to start OpenClaw
echo 2. Access dashboard at http://127.0.0.1:18789
echo 3. Configure the new token in Control UI
echo ========================================

pause
