@echo off
@setlocal enableextensions
@cd /d "%~dp0%"

start "" "bin\x64w_MT\AutoHotkey.exe" "send2Main.ahk" %*