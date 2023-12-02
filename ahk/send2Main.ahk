#Include lib\std.ahk
#Include lib\messaging.ahk

#SingleInstance Force

SetCurrentWinTitle(SENDNAME)

; check that mediacenter is actually running
DetectHiddenWindows(true)
if (!WinExist(MAINNAME)) {
    ErrorMsg(MAINNAME . " is not running", true)
}

sendListToMain(A_Args)
ExitApp()