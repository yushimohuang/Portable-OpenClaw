@echo off
setlocal EnableDelayedExpansion

:: ============================================
:: Portable OpenClaw 一键更新工具 (修复版)
:: 自动修复环境变量和编码问题
:: ============================================

:: 设置UTF-8编码
call :SetUTF8

:: 修复系统PATH环境变量
call :FixSystemPath

:: 检查并配置Git
call :SetupGit

echo.
echo ============================================
echo        正在更新 Portable OpenClaw...
echo ============================================
echo.

:: 停止现有进程
echo [1/5] 停止现有进程...
taskkill /F /IM node.exe >nul 2>&1
taskkill /F /IM openclaw.exe >nul 2>&1
ping -n 2 127.0.0.1 >nul
echo      完成
echo.

:: 备份
echo [2/5] 备份当前版本...
if not exist "backups" mkdir "backups"
set "backupDir=backups\openclaw-main-backup-%date:~0,4%%date:~5,2%%date:~8,2%-%time:~0,2%%time:~3,2%%time:~6,2%"
set "backupDir=!backupDir: =0!"
if exist "openclaw-main" (
    xcopy "openclaw-main" "!backupDir!" /E /I /Y /Q >nul 2>&1
    echo      已备份到 !backupDir!
) else (
    echo      未找到旧版本，跳过备份
)
echo.

:: 下载更新
echo [3/5] 下载最新版本...
if exist "temp" rmdir /s /q "temp" 2>nul
mkdir "temp" 2>nul
cd temp

echo      正在安装 openclaw@latest...
call ..\nodejs\npm.cmd install openclaw@latest 2>&1
if !errorlevel! neq 0 (
    echo.
    echo [错误] npm install 失败！
    echo 可能的原因：
    echo   1. 网络连接问题
    echo   2. npm缓存损坏
    echo   3. 权限不足
    echo.
    echo 请尝试以下解决方案：
    echo   1. 检查网络连接
    echo   2. 运行: npm cache clean --force
    echo   3. 以管理员身份运行此脚本
    cd ..
    pause
    exit /b 1
)
cd ..
echo      完成
echo.

:: 替换文件
echo [4/5] 替换文件...
if exist "openclaw-main" rmdir /s /q "openclaw-main" 2>nul
xcopy "temp\node_modules\openclaw" "openclaw-main" /E /I /Y /Q >nul 2>&1
echo      完成
echo.

:: 清理
echo [5/5] 清理临时文件...
if exist "temp" rmdir /s /q "temp" 2>nul
echo      完成
echo.

echo ============================================
echo              更新完成！
echo ============================================
echo.

:: 显示版本
echo 当前版本:
nodejs\node.exe openclaw-main\openclaw.mjs --version 2>nul
if !errorlevel! neq 0 (
    echo [警告] 无法获取版本信息，但更新可能已成功
)
echo.
echo 请运行 "一键启动.bat" 重新启动 OpenClaw
echo.
pause
exit /b 0

:: ============================================
:: 子程序：设置UTF-8编码
:: ============================================
:SetUTF8
chcp 65001 >nul 2>&1
if !errorlevel! neq 0 (
    :: 如果chcp失败，尝试使用reg设置
    reg add "HKCU\Console" /v CodePage /t REG_DWORD /d 65001 /f >nul 2>&1
)
set "LANG=zh_CN.UTF-8"
exit /b 0

:: ============================================
:: 子程序：修复系统PATH
:: ============================================
:FixSystemPath
set "SystemPathAdded=0"

:: 检查并添加关键系统路径
call :AddToPath "C:\Windows"
call :AddToPath "C:\Windows\System32"
call :AddToPath "C:\Windows\System32\Wbem"
call :AddToPath "C:\Windows\System32\WindowsPowerShell\v1.0"

if !SystemPathAdded! equ 1 (
    echo [信息] 已修复系统PATH环境变量
)
exit /b 0

:: ============================================
:: 子程序：添加路径到PATH
:: ============================================
:AddToPath
echo !PATH! | find /i "%~1" >nul 2>&1
if !errorlevel! neq 0 (
    set "PATH=%~1;!PATH!"
    set "SystemPathAdded=1"
)
exit /b 0

:: ============================================
:: 子程序：配置Git
:: ============================================
:SetupGit
echo [检查] Git环境...

:: 检查系统Git
git --version >nul 2>&1
if !errorlevel! equ 0 (
    echo      系统Git已安装: 
    git --version
    exit /b 0
)

:: 检查便携版Git
set "PortableGitPath=%~dp0PortableGit\cmd"
if exist "!PortableGitPath!\git.exe" (
    echo      使用便携版Git
    set "PATH=!PortableGitPath!;!PATH!"
    "!PortableGitPath!\git.exe" --version
    exit /b 0
)

:: 检查其他位置的Git
if exist "%~dp0..\PortableGit\cmd\git.exe" (
    set "PortableGitPath=%~dp0..\PortableGit\cmd"
    echo      使用上级目录的便携版Git
    set "PATH=!PortableGitPath!;!PATH!"
    "!PortableGitPath!\git.exe" --version
    exit /b 0
)

:: 未找到Git
echo [警告] 未找到Git！
echo      npm可能需要Git来下载某些包
echo      建议运行 setup-git.ps1 配置便携版Git
echo.
exit /b 0
