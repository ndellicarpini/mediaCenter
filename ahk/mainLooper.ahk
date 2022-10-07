#SingleInstance Force

#Include lib\std.ahk

SetCurrentWinTitle(MAINLOOP)

globalCount   := 0
hungCount     := 0
resetCount    := 0
maxResetCount := 0

if (A_Args.Length > 0) {
    if (IsNumber(A_Args[1])) {
        maxResetCount := Integer(A_Args[1])
    }
    else if (StrLower(A_Args[1]) = "-clean") {
        Run A_ScriptDir . "\" . "startMain.cmd", A_ScriptDir, "Hide"
        
        ExitApp()
    }
}

loop {
    mainID := WinHidden(MAINNAME)

    ; check for main process or pre-init crashed main
    if (!mainID && !WinShown("main.ahk")) {
        Run A_ScriptDir . "\" . "startMain.cmd -quiet -backup", A_ScriptDir, "Hide"

        resetCount += 1
        Sleep(500)
        continue
    }
    
    if (globalCount > 30 && DllCall("IsHungAppWindow", "Ptr", mainID)) {
        hungCount += 1

        if (hungCount > 5) {
            ProcessKill(WinGetPID(mainID), false)
            
            Sleep(500)
            Run A_ScriptDir . "\" . "startMain.cmd -quiet -backup", A_ScriptDir, "Hide"
            
            hungCount := 0
            resetCount += 1
        }
    }
    else if (hungCount > 0) {
        hungCount := 0
    }

    if (maxResetCount > 0 && resetCount >= maxResetCount) {
        ExitApp()
    }

    globalCount += 1
    Sleep(1000)
}