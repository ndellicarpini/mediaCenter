; This script appends files to be included based on the global.cfg's custom
; script directory. This script will add '#Include x' for every '.ahk' file in that
; directory

#SingleInstance Force

#Include lib\std.ahk
#Include lib\confio.ahk

globalConfig := readConfig("global.cfg",,"brackets", "Plugins")

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
if (globalConfig.items.Has("AHKPluginDir") && globalConfig.items["AHKPluginDir"] != "") {
    pluginIncludeDirs.Push(globalConfig.items["AHKPluginDir"])
}
if (globalConfig.items.Has("ConsolePluginDir") && globalConfig.items["ConsolePluginDir"] != "") {
    pluginIncludeDirs.Push(globalConfig.items["ConsolePluginDir"])
}
if (globalConfig.items.Has("InputPluginDir") && globalConfig.items["InputPluginDir"] != "") {
    pluginIncludeDirs.Push(globalConfig.items["InputPluginDir"])
}
if (globalConfig.items.Has("ProgramPluginDir") && globalConfig.items["ProgramPluginDir"] != "") {
    pluginIncludeDirs.Push(globalConfig.items["ProgramPluginDir"])
} 

mainString := fileToString("main.ahk")  
eol := getEOL(mainString)

; build new dynamic include string
includeString := DYNASTART . eol
for dir in pluginIncludeDirs {
    loop files (validateDir(dir) . "*.ahk"), "R" {
        includeString .= "#Include " . A_LoopFileShortPath . eol
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
ExitApp()