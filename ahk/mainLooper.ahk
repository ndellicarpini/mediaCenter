#Include lib-mc\std.ahk

#SingleInstance Force

SetCurrentWinTitle(MAINLOOP)

hungCount     := 0
resetCount    := 0
maxResetCount := 0

if (A_Args.Length > 0 && IsNumber(A_Args[1])) {
    maxResetCount := Integer(A_Args[1])
}

loop {
    mainID := WinHidden(MAINNAME)

    if (!mainID) {
        Run A_ScriptDir . "\" . "startMain.cmd -quiet -backup", A_ScriptDir, "Hide"

        resetCount += 1
        Sleep(500)
        continue
    }
    
    if (DllCall("IsHungAppWindow", "Ptr", mainID)) {
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

    Sleep(1000)
}