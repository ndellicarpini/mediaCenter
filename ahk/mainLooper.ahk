#Include lib-mc\std.ahk

#SingleInstance Force
#WarnContinuableException Off

setCurrentWinTitle(MAINLOOP)

loop {
    if (!WinHidden(MAINNAME)) {
        Run A_ScriptDir . "\" . "startMain.cmd -quiet -backup", A_ScriptDir, "Hide"
    }

    Sleep(1000)
}