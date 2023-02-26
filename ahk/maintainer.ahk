#SingleInstance Force

#Include lib\std.ahk

SetCurrentWinTitle(MAINLOOP)

globalCount   := 0
hungCount     := 0

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
    if (!mainID && !WinHidden("main.ahk")) {
        Run A_ScriptDir . "\" . "startMain.cmd -quiet -backup", A_ScriptDir, "Hide"

        Sleep(2000)
        continue
    }
    
    if (mainID && DllCall("IsHungAppWindow", "Ptr", mainID)) {
        hungCount += 1

        if (hungCount > 14) {
            ProcessKill(WinGetPID(mainID), false)
            Sleep(500)

            Run A_ScriptDir . "\" . "startMain.cmd -quiet -backup", A_ScriptDir, "Hide"
            
            hungCount := 0
            
            Sleep(2000)
            continue
        }
    }
    else if (hungCount > 0) {
        hungCount := 0
    }

    Sleep(1000)
}
