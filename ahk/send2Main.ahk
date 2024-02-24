#Include lib\std.ahk
#Include lib\messaging.ahk

#SingleInstance Force

SetCurrentWinTitle(SENDNAME)

; check that mediacenter is actually running
DetectHiddenWindows(true)
if (!WinExist(MAINNAME)) {
    MsgBox(MAINNAME . " is not running")
}

sendListToMain(A_Args)

Sleep(100)
ProcessClose(DllCall("GetCurrentProcessId"))