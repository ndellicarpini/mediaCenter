#Include lib-mc\std.ahk
#Include lib-mc\messaging.ahk

; check that mediacenter is actually running
DetectHiddenWindows(true)
if (!WinExist("MediaCenterMain")) {
    ErrorMsg("MediaCenterMain is not running", true)
}

sendListToMain(A_Args)

Sleep(100)
ExitApp()