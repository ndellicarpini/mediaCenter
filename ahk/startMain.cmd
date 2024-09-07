@echo off
@setlocal enableextensions
@cd /d "%~dp0%"

start /w "" "bin\AutoHotkey64.exe" "maincluder.ahk"
start "" "bin\AutoHotkey64.exe" "main.ahk" %*