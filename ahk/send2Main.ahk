#Include lib-mc\std.ahk
#Include lib-mc\messaging.ahk

; need to put this here because i suck
global globalConfig := Map()

; check that mediacenter is actually running
DetectHiddenWindows(true)
if (!WinExist("MediaCenterMain")) {
    ErrorMsg("MediaCenterMain is not running", true)
}

sendListToMain(A_Args)

ExitApp()