#Include lib-mc\std.ahk
#Include lib-mc\confio.ahk

#SingleInstance Force
#WarnContinuableException Off

setCurrentWinTitle(MAINLOOP)

sleepTime := readConfig("config\global.txt",, "brackets", "General").items["AvgLoopSleep"] * 5

loop {
    if (!WinHidden(MAINNAME)) {
        Run A_ScriptDir . "\" . "startMain.cmd -quiet", A_ScriptDir, "Hide"
    }

    Sleep(sleepTime)
}