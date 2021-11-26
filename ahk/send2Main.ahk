#Include lib-mc\std.ahk
#Include lib-mc\messaging.ahk

; check that mediacenter is actually running
DetectHiddenWindows(true)
if (!WinExist("MediaCenterMain")) {
    ErrorMsg("MediaCenterMain is not running", true)
}

; send all args passed to script and bookend strings
sendMessageToMain(MESSAGE_START)

for item in A_Args {
    sendMessageToMain(item)
}

sendMessageToMain(MESSAGE_END)

ExitApp()