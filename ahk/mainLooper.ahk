#Include lib-mc\std.ahk

#SingleInstance Force

setCurrentWinTitle(MAINLOOP)

hungCount := 0
loop {
    mainID := WinHidden(MAINNAME)

    if (!mainID) {
        Run A_ScriptDir . "\" . "startMain.cmd -quiet -backup", A_ScriptDir, "Hide"

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
        }
    }
    else {
        hungCount := 0
    }

    Sleep(1000)
}