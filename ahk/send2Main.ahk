#Include lib\std.ahk
#Include lib\messaging.ahk

#SingleInstance Force

SetCurrentWinTitle(SENDNAME)

; check that mediacenter is actually running
DetectHiddenWindows(true)
if (!WinExist(MAINNAME)) {
    Run(A_ScriptDir . "\" . "startMain.cmd -quiet -backup", A_ScriptDir, "Hide")
    Sleep(500)
}

sendListToMain(A_Args)

Sleep(100)
ProcessClose(DllCall("GetCurrentProcessId"))