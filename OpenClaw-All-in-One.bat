@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title Portable OpenClaw 一体化启动工具
color 0B

:: ========================================
:: 配置区域（所有路径必须在单行）
:: ========================================
set "WORK_DIR=%~dp0"
set "WORK_DIR=%WORK_DIR:~0,-1%"
set "NODE=%WORK_DIR%\nodejs\node.exe"
set "NPM=%WORK_DIR%\nodejs\npm.cmd"
set "CLI=%WORK_DIR%\openclaw-main\openclaw.mjs"
set "DATA_DIR=%WORK_DIR%\data"
set "CONFIG_FILE=%DATA_DIR%\config.json"

:: ========================================
:: 主菜单
:: ========================================
:MAIN_MENU
cls
echo ========================================
echo        Portable OpenClaw 一体化启动工具
echo ========================================
echo.
echo [1] 检测版本并更新
echo [2] 配置 AI 模型
echo [3] 启动 OpenClaw 网关
echo [4] 完整流程（推荐）
echo [5] 打开模型配置网页
echo [6] 退出
echo.
set /p CHOICE=请选择操作 [1-6]: 
if "%CHOICE%"=="1" goto :CHECK_UPDATE
if "%CHOICE%"=="2" goto :CONFIG_MODEL
if "%CHOICE%"=="3" goto :START_GATEWAY
if "%CHOICE%"=="4" goto :FULL_FLOW
if "%CHOICE%"=="5" goto :OPEN_CONFIG_PAGE
if "%CHOICE%"=="6" exit /b 0
goto :MAIN_MENU

:: ========================================
:: 完整流程
:: ========================================
:FULL_FLOW
echo.
echo ========================================
echo        开始完整流程...
echo ========================================
echo.
goto :CHECK_UPDATE

:: ========================================
:: 版本检测与更新
:: ========================================
:CHECK_UPDATE
echo.
echo ========================================
echo        步骤 1: 版本检测
echo ========================================
echo.

if not exist "%CLI%" (
    echo [Error] OpenClaw 核心文件未找到！
    echo 路径：%CLI%
    pause
    goto :MAIN_MENU
)

if not exist "%NODE%" (
    echo [Error] Node.js 未找到！
    echo 路径：%NODE%
    pause
    goto :MAIN_MENU
)

echo [Info] 检测当前版本...
set "CURRENT_VERSION="
for /f "delims=" %%i in ('"%NODE%" "%CLI%" --version 2^>^&1') do (
    set "CURRENT_VERSION=%%i"
)

if not defined CURRENT_VERSION (
    echo [Warning] 无法获取当前版本信息
    set "CURRENT_VERSION=未知"
) else (
    for /f "tokens=2" %%v in ("!CURRENT_VERSION!") do set "CURRENT_VERSION=%%v"
)

echo [当前版本] !CURRENT_VERSION!
echo.

echo [Info] 查询最新版本...
set "LATEST_VERSION="
for /f "delims=" %%i in ('"%NPM%" view openclaw@latest version 2^>^&1') do (
    set "LATEST_VERSION=%%i"
)

if not defined LATEST_VERSION (
    echo [Warning] 无法获取最新版本信息（网络问题）
    pause
    goto :CONFIG_MODEL_SECTION
)

echo [最新版本] !LATEST_VERSION!
echo.

if "!CURRENT_VERSION!"=="!LATEST_VERSION!" (
    echo ========================================
    echo   已是最新版本！
    echo ========================================
    timeout /t 2 /nobreak >nul
    goto :CONFIG_MODEL_SECTION
) else (
    echo ========================================
    echo   发现新版本！
    echo ========================================
    set /p UPDATE_CHOICE=是否更新到最新版本？[Y/N 默认:Y]: 
    if /i "!UPDATE_CHOICE!"=="N" goto :CONFIG_MODEL_SECTION
    if "!UPDATE_CHOICE!"=="" set UPDATE_CHOICE=Y
    goto :DO_UPDATE
)

:: ========================================
:: 执行更新
:: ========================================
:DO_UPDATE
echo.
echo ========================================
echo        正在更新 OpenClaw...
echo ========================================
echo.

echo [1/5] 停止现有进程...
taskkill /F /IM node.exe >nul 2>&1
echo       完成

echo [2/5] 备份当前版本...
if not exist "backups" mkdir "backups"
set "BACKUP_DIR=backups\openclaw-backup-%date:~0,4%%date:~5,2%%date:~8,2%"
if exist "openclaw-main" (
    xcopy "openclaw-main" "!BACKUP_DIR!" /E /I /Y /Q >nul
    echo       已备份到 !BACKUP_DIR!
)

echo [3/5] 下载最新版本...
if exist "temp" rmdir /s /q "temp" 2>nul
mkdir "temp" 2>nul
cd temp
call "%NPM%" install openclaw@latest 2>&1
if !errorlevel! neq 0 (
    echo.
    echo [Error] 更新失败！
    cd ..
    pause
    goto :MAIN_MENU
)
cd ..

echo [4/5] 替换文件...
if exist "openclaw-main" rmdir /s /q "openclaw-main" 2>nul
xcopy "temp\node_modules\openclaw" "openclaw-main" /E /I /Y /Q >nul
echo       完成

echo [5/5] 清理临时文件...
if exist "temp" rmdir /s /q "temp" 2>nul
echo       完成

echo.
echo ========================================
echo   更新完成！
echo ========================================
timeout /t 2 /nobreak >nul
goto :CONFIG_MODEL_SECTION

:: ========================================
:: 模型配置
:: ========================================
:CONFIG_MODEL_SECTION
echo.
echo ========================================
echo        步骤 2: 配置 AI 模型
echo ========================================
echo.

if exist "%CONFIG_FILE%" (
    findstr /i "apiKey" "%CONFIG_FILE%" >nul
    if !errorlevel! equ 0 (
        echo [Info] 检测到已有模型配置
        set /p SKIP_CONFIG=是否跳过模型配置？[Y/N 默认:Y]: 
        if /i "!SKIP_CONFIG!"=="Y" goto :START_GATEWAY_SECTION
        if "!SKIP_CONFIG!"=="" goto :START_GATEWAY_SECTION
    )
)

echo [可选模型提供商]
echo 1. 通义千问 (阿里云) - 免费额度最多
echo 2. DeepSeek - 编程首选
echo 3. Kimi - 长文档利器
echo 4. 智谱 AI - 学术、中文 NLP
echo 5. 硅基流动 - 模型聚合
echo 6. Ollama 本地 - 完全免费
echo 7. 自定义/中转
echo.
set /p PROVIDER=请选择模型提供商 [1-7]: 
if "%PROVIDER%"=="" set PROVIDER=1

if "%PROVIDER%"=="1" (
    set "BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1"
    set "DEFAULT_MODEL=qwen-turbo"
    set "PROVIDER_NAME=通义千问"
) else if "%PROVIDER%"=="2" (
    set "BASE_URL=https://api.deepseek.com"
    set "DEFAULT_MODEL=deepseek-chat"
    set "PROVIDER_NAME=DeepSeek"
) else if "%PROVIDER%"=="3" (
    set "BASE_URL=https://api.moonshot.cn/v1"
    set "DEFAULT_MODEL=moonshot-v1-8k"
    set "PROVIDER_NAME=Kimi"
) else if "%PROVIDER%"=="4" (
    set "BASE_URL=https://open.bigmodel.cn/api/paas/v4"
    set "DEFAULT_MODEL=glm-4-flash"
    set "PROVIDER_NAME=智谱 AI"
) else if "%PROVIDER%"=="5" (
    set "BASE_URL=https://api.siliconflow.cn/v1"
    set "DEFAULT_MODEL=Qwen/Qwen2.5-7B-Instruct"
    set "PROVIDER_NAME=硅基流动"
) else if "%PROVIDER%"=="6" (
    set "BASE_URL=http://127.0.0.1:11434/v1"
    set "DEFAULT_MODEL=qwen2.5:7b"
    set "PROVIDER_NAME=Ollama 本地"
) else if "%PROVIDER%"=="7" (
    set "BASE_URL="
    set "DEFAULT_MODEL="
    set "PROVIDER_NAME=自定义"
)

echo.
set /p APIKEY=请输入 API Key (留空跳过): 
if "%APIKEY%"=="" goto :START_GATEWAY_SECTION

set /p MODEL=请输入模型名称 [默认:%DEFAULT_MODEL%]: 
if "%MODEL%"=="" set MODEL=%DEFAULT_MODEL%

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

powershell -Command "$json = @{ plugins = @{ allow = @('device-pair','phone-control','talk-voice','feishu'); entries = @{} }; channels = @{ feishu = @{ allowFrom = @('*') } }; models = @( @{ id = 'default'; provider = 'openai-compatible'; baseUrl = '%BASE_URL%'; apiKey = '%APIKEY%'; model = '%MODEL%'; systemPrompt = '你是一个专业的编程助手。' } ) }; $json | ConvertTo-Json -Depth 5 | Out-File -FilePath '%CONFIG_FILE%' -Encoding UTF8 -NoNewline"

echo.
echo ========================================
echo   模型配置完成！
echo ========================================
goto :START_GATEWAY_SECTION

:: ========================================
:: 启动网关
:: ========================================
:START_GATEWAY_SECTION
echo.
echo ========================================
echo        步骤 3: 启动 OpenClaw 网关
echo ========================================
echo.

for /f "tokens=2" %%i in ('tasklist /fi "imagename eq node.exe" /fo table /nh 2^>nul ^| findstr /i "node.exe"') do (
    taskkill /F /PID %%i /T >nul 2>&1
)

if not exist "%NODE%" (
    echo [Error] Node.js 未找到！
    pause
    goto :MAIN_MENU
)

if not exist "%CLI%" (
    echo [Error] OpenClaw 核心未找到！
    pause
    goto :MAIN_MENU
)

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

set "PATH=%WORK_DIR%\nodejs;%PATH%"

echo ========================================
echo        启动 OpenClaw Gateway...
echo ========================================
echo [控制台] http://127.0.0.1:18789
echo ========================================
echo.

start "OpenClaw" "%NODE%" "%CLI%" gateway --port 18789 --verbose --allow-unconfigured

timeout /t 3 /nobreak >nul
start "" "http://127.0.0.1:18789"

echo.
echo ========================================
echo   OpenClaw 启动成功！
echo ========================================
pause
goto :MAIN_MENU

:: ========================================
:: 单独配置模型
:: ========================================
:CONFIG_MODEL
goto :CONFIG_MODEL_SECTION

:: ========================================
:: 单独启动网关
:: ========================================
:START_GATEWAY
goto :START_GATEWAY_SECTION

:: ========================================
:: 打开模型配置网页
:: ========================================
:OPEN_CONFIG_PAGE
echo.
if exist "%WORK_DIR%\model-config.html" (
    start "" "%WORK_DIR%\model-config.html"
) else (
    echo [Warning] model-config.html 未找到！
)
pause
goto :MAIN_MENU

:: ========================================
:: 退出
:: ========================================
:EXIT
exit /b 0