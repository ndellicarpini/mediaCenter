@echo off
@setlocal enableextensions
@cd /d "%~dp0%"

start /w "" "bin\x64w\AutoHotkey.exe" "mainInclude.ahk"
start "" "bin\x64w\AutoHotkey.exe" "main.ahk" %*