; This script appends files to be included based on the config\global.txt's custom
; script directory. This script will add '#Include x' for every '.ahk' file in that
; directory

#SingleInstance Force
#WarnContinuableException Off

#Include lib-mc\std.ahk
#Include lib-mc\confio.ahk

generalConfig := readConfig("config\global.txt",,"brackets", "General")

; only run if customlibdir exists
if (generalConfig.items.Has("CustomLibDir") && generalConfig.items["CustomLibDir"] != "") {
    customLibDir := validateDir(generalConfig.items["CustomLibDir"])

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
        pid := WinGetPID("MediaCenterMain")

        ProcessClose(pid)
    }

    mainFile := FileOpen("main.ahk", "r")
    mainString := mainFile.Read()
    mainFile.Close()    

    eol := getEOL(mainString)

    ; build new dynamic include string
    includeString := DYNASTART . eol
    loop files (customLibDir . "*.ahk"), "R" {
        includeString .= "#Include " . A_LoopFileShortPath . eol
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
}