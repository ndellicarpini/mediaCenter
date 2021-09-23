global MESSAGE_VAL := 0x004A
global MESSAGE_START := "START_TRANSMISSION" ; marks beginning of a data set being sent to main
global MESSAGE_END := "END_TRANSMISSION"     ; marks endd of a data set being sent to main

global MESSAGE_ENABLE := false ; if received MESSAGE_START -> true
global MESSAGE_DATA := []

; enables the OnMessage listener for send2Main
;
; returns null
enableMainMessageListener() {
    OnMessage(MESSAGE_VAL, "handleMessage")
}

; disables the OnMessage listener for send2Main
;
; returns null
disableMainMessageListener() {
    OnMessage(MESSAGE_VAL, "handleMessage", 1)
}

; sends a message to main and waits to confirm message was recieved
;  message - message to send to main
;  waitTime - ms to wait for message to be confirmed recieved
;
; returns null
sendMessageToMain(message, waitTime := 5000) {
    SetTitleMatchMode(3)
    DetectHiddenWindows(true)

    stringBuffer := BufferAlloc(3 * A_PtrSize)
    stringSize := 2 * (StrLen(message) + 1)

    NumPut("Ptr", stringSize, "Ptr", StrPtr(message), stringBuffer, A_PtrSize)

    if (SendMessage(MESSAGE_VAL, 0, stringBuffer,, "MediaCenterMain",,,, waitTime) != 0) {
        MsgBox("
        (
            ERROR
            Did not recieve confirmation from
            MediaCenterMain within 5000ms
        )")
    
        ExitApp()
    }
}

; recieves a message bookended by MESSAGE_START and MESSAGE_END and runs whatever functions
; should run when a specific message is recieved
;  parameters are default for a function called by OnMessage
;
; returns null
handleMessage(wParam, lParam, msg, hwnd) {
    stringAddress := NumGet(lParam, (2 * A_PtrSize), "Ptr")
    messageData := StrGet(stringAddress)

    if (messageData = MESSAGE_START) {
        MESSAGE_ENABLE := true
    }
    else if (MESSAGE_ENABLE) {
        if (messageData = MESSAGE_END) {
            MESSAGE_ENABLE := false

            ; send message to main
            mainMessage := MESSAGE_DATA
            MESSAGE_DATA := []
        }
        else {
            MESSAGE_DATA.Push(messageData)
        }
    }
}