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
    
    ; append \ to end of dir if it doesnt exist
    customLibDir := generalConfig.items["CustomLibDir"]
    if (!RegExMatch(customLibDir, "U).*\\$")) {
        customLibDir .= "\"
    }

    ; check if main exists
    if (!FileExist("main.ahk")) {
        MsgBox("
        (
            ERROR
            main.ahk does not exist
            that is not good
        )")
    }

    ; check that dir specified by custom lib exists
    else if (!DirExist(customLibDir)) {
        MsgBox("
        (
            ERROR
            CustomLibDir Not Found    
        )")
    }

    else {
        ; close main if its already running
        if (mediaCenterRunning()) {
            DetectHiddenWindows(true)
            pid := WinGetPID("MediaCenterMain")

            ProcessClose(pid)
        }

        mainFile := FileOpen("main.ahk", "r")
        mainString := mainFile.Read()
        mainFile.Close()    

        eol := getEOL(mainString)

        ; create dynamic include string
        dynaStringStart := "; ----- DO NOT EDIT: DYNAMIC INCLUDE START -----"
        dynaStringEnd   := "; ----- DO NOT EDIT: DYNAMIC INCLUDE END   -----"

        includeString := dynaStringStart . eol
        loop files (customLibDir . "*.ahk") {
            includeString .= "#Include " . A_LoopFileShortPath . eol
        }
        includeString .= dynaStringEnd . eol

        toReplace := ""
        startReplace := false

        ; if dynamic include has already been generated
        if (InStr(mainString, dynaStringStart)) {
            loop parse mainString, eol {
                if (InStr(A_LoopField, dynaStringStart)) {
                    toReplace .= A_LoopField . eol
                    startReplace := true
                }
                else if (InStr(A_LoopField, dynaStringEnd)) {
                    toReplace .= A_LoopField . eol
                    startReplace := false

                    break
                }
                else if (startReplace) {
                    toReplace .= A_LoopField . eol
                }
            }
        }
        else {
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
}