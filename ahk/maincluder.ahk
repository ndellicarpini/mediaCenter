; This script appends files to be included based on the global.cfg's custom
; script directory. This script will add '#Include x' for every '.ahk' file in that
; directory

#SingleInstance Force

#Include lib\std.ahk
#Include lib\config.ahk

pluginConfig := Config("global.cfg", "ini").data["Plugins"]

; check if main exists
if (!FileExist("main.ahk")) {
    ErrorMsg(
        (
            "
            main.ahk does not exist
            that is not good
            "
        ),
        true
    )
}

; close main if its already running
if (WinHidden(MAINNAME)) {
    DetectHiddenWindows(true)
    pid := WinGetPID(MAINNAME)

    ProcessClose(pid)
}

pluginIncludeDirs := []
if (pluginConfig.Has("AHKPluginDir") && pluginConfig["AHKPluginDir"] != "") {
    pluginIncludeDirs.Push(pluginConfig["AHKPluginDir"])
}
if (pluginConfig.Has("ConsolePluginDir") && pluginConfig["ConsolePluginDir"] != "") {
    pluginIncludeDirs.Push(pluginConfig["ConsolePluginDir"])
}
if (pluginConfig.Has("InputPluginDir") && pluginConfig["InputPluginDir"] != "") {
    pluginIncludeDirs.Push(pluginConfig["InputPluginDir"])
}
if (pluginConfig.Has("ProgramPluginDir") && pluginConfig["ProgramPluginDir"] != "") {
    pluginIncludeDirs.Push(pluginConfig["ProgramPluginDir"])
} 

mainString := fileToString("main.ahk")  
eol := getEOL(mainString)

; build new dynamic include string
includeString := DYNASTART . eol
for dir in pluginIncludeDirs {
    loop files (validateDir(dir) . "*.ahk"), "R" {
        includeString .= "#Include " . A_LoopFilePath . eol
    }
}
includeString .= DYNAEND . eol

toReplace := getDynamicIncludes(mainString)
startReplace := false

; if dynamic include has already been generated
if (toReplace = "") {
    loop parse mainString, eol {
        if (InStr(A_LoopField, "#Include ")) {
            toReplace := A_LoopField
            includeString .= eol . A_LoopField
            break
        }
    }
}

newMainString := StrReplace(mainString, toReplace, includeString)

mainFile := FileOpen("main.ahk", "w")
mainFile.Write(newMainString)
mainFile.Close()

Sleep(100)
ProcessClose(DllCall("GetCurrentProcessId"))