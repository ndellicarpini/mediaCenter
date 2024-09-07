@echo off
@setlocal enableextensions
@cd /d "%~dp0%"

start "" "bin\AutoHotkey64.exe" "send2Main.ahk" %*