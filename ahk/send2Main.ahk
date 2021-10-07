#Include lib-mc\std.ahk
#Include lib-mc\messaging.ahk

; check that mediacenter is actually running
DetectHiddenWindows(true)
if (!WinExist("MediaCenterMain")) {
    MsgBox("
    (
        ERROR
        MediaCenterMain is not running
    )")

    return
}

; send all args passed to script and bookend strings
sendMessageToMain(MESSAGE_START)

for item in A_Args {
    sendMessageToMain(item)
}

sendMessageToMain(MESSAGE_END)

ExitApp()