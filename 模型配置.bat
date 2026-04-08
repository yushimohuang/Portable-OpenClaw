@echo off
chcp 65001 >nul
title Portable OpenClaw 阿里云一键配置
color 0B

echo ========================================
echo   Portable OpenClaw 阿里云一键配置
echo   免费额度：100 万 Token
echo ========================================
echo.

set "WORK_DIR=%~dp0"
set "NODE=%WORK_DIR%nodejs\node.exe"
set "CLI=%WORK_DIR%openclaw-main\openclaw.mjs"
set "DATA_DIR=%WORK_DIR%data"
set "CONFIG_FILE=%DATA_DIR%\config.json"

:: 1. 检查文件
if not exist "%NODE%" (
    echo [Error] Node.js not found
    pause
    exit /b 1
)

if not exist "%CLI%" (
    echo [Error] OpenClaw core not found
    pause
    exit /b 1
)

:: 2. 显示获取 API Key 指引
echo [Step 1] 获取阿里云 API Key
echo ========================================
echo.
echo   1. 访问： https://dashscope.console.aliyun.com/apiKey 
echo   2. 用支付宝/淘宝账号登录
echo   3. 完成实名认证
echo   4. 点击「创建新的 API-KEY」
echo   5. 复制 Key（格式：sk-xxxxxxxx）
echo.
echo [获取 API Key]
echo   https://dashscope.console.aliyun.com/apiKey 
echo.
echo ========================================
echo.

:: 3. 输入 API Key 和模型名称
set /p APIKEY=请输入您的阿里云 API Key: 
set /p MODEL=请输入模型名称 [默认:qwen-turbo]: 

if "%MODEL%"=="" set MODEL=qwen-turbo

:: 4. 创建配置
echo.
echo [Step 2] 写入配置...

if "%APIKEY%"=="" (
    echo [Warning] 未输入 API Key，创建空配置
    goto :WRITE_EMPTY
)

:: 使用 PowerShell 写入正确 JSON（注意：API 地址已修正）
powershell -Command "$json = @{ plugins = @{ allow = @('device-pair','phone-control','talk-voice','feishu'); entries = @{} }; channels = @{ feishu = @{ allowFrom = @('*') } }; models = @( @{ id = 'default'; provider = 'openai-compatible'; baseUrl = 'https://dashscope.aliyuncs.com/compatible-mode/v1'; apiKey = '%APIKEY%'; model = '%MODEL%'; systemPrompt = '你是一个专业的编程助手，请用简洁的中文回答。' } ) }; $json | ConvertTo-Json -Depth 5 | Out-File -FilePath '%CONFIG_FILE%' -Encoding UTF8 -NoNewline"
echo      ✓ 配置已写入
goto :DONE

:WRITE_EMPTY
powershell -Command "$json = @{ plugins = @{ allow = @('device-pair','phone-control','talk-voice','feishu'); entries = @{} }; channels = @{ feishu = @{ allowFrom = @('*') } }; models = @() }; $json | ConvertTo-Json -Depth 5 | Out-File -FilePath '%CONFIG_FILE%' -Encoding UTF8 -NoNewline"
echo      ✓ 空配置已创建

:DONE
echo.
echo ========================================
echo   ✅ 配置完成！
echo ========================================
echo.
echo [模型信息]
echo   提供商：阿里云 DashScope
echo   模型：%MODEL%
echo   API 地址： https://dashscope.aliyuncs.com/compatible-mode/v1 
echo   免费额度：100 万 Token（90 天）
echo.
echo [下一步]
echo   1. 运行「一键启动.bat」
echo   2. 打开 http://127.0.0.1:18789
echo   3. 测试 AI 对话
echo.
echo ========================================
pause