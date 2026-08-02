#SingleInstance Force

#Include lib\std.ahk

writeLog(text, prefix := "") {
    if (!DirExist("data\")) {
        DirCreate("data\")
    }
    if (!DirExist("data\logs")) {
        DirCreate("data\logs")
    }

    if (FileExist("data\logs\log.txt")) {
        modifiedTime := FileGetTime("data\logs\log.txt", "M")
        if (SubStr(modifiedTime, 1, 8) != SubStr(A_Now, 1, 8)) {
            FileMove("data\logs\log.txt", "data\logs\log." . FormatTime(modifiedTime, "yyyy-MM-dd") . ".txt", true)
        }
    }

    newLine := "[" . FormatTime(, "MM-dd-yyyy HH:mm:ss") . ((prefix != "") ? ("] " . prefix . " | ") : "] ") . text . "`r`n"
    FileAppend(newLine, "data\logs\log.txt")
}

SetCurrentWinTitle(MAINLOOP)

hungCount := 0

if (A_Args.Length > 0) {
    if (IsNumber(A_Args[1])) {
        maxResetCount := Integer(A_Args[1])
    }
    else if (StrLower(A_Args[1]) = "-clean") {
        Run(A_ScriptDir . "\" . "startMain.cmd", A_ScriptDir, "Hide")
        
        ProcessClose(DllCall("GetCurrentProcessId"))
    }
}

loop {
    mainID := WinHidden(MAINNAME)

    ; check for main process or pre-init crashed main
    if (!mainID && !(WinHidden("main.ahk") && WinGetProcessPath("main.ahk") = A_AhkPath)) {
        Run(A_ScriptDir . "\" . "startMain.cmd -quiet -backup", A_ScriptDir, "Hide")

        Sleep(2000)
        continue
    }

    if (mainID && DllCall("IsHungAppWindow", "Ptr", mainID)) {
        hungCount += 1

        if (hungCount > 14) {
            writeLog("KILLING MAIN - HUNG", "MAINTAINER")
            ProcessKill(WinGetPID(mainID), false)
            Sleep(500)
            continue
        }
    }
    else if (hungCount > 0) {
        hungCount := 0
    }

    Sleep(1000)
}
