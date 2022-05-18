global MESSAGE_VAL := 0x004A
global MESSAGE_START := "START_TRANSMISSION" ; marks beginning of a data set being sent to main
global MESSAGE_END := "END_TRANSMISSION"     ; marks endd of a data set being sent to main

global MESSAGE_ENABLE := false ; if received MESSAGE_START -> true
global MESSAGE_DATA := []

; sends a message to main and waits to confirm message was recieved
;  message - message to send to main
;  waitTime - ms to wait for message to be confirmed recieved
;
; returns null
sendMessageToMain(message, waitTime := 5000) {
    SetTitleMatchMode(3)
    DetectHiddenWindows(true)

    stringBuffer := Buffer(3 * A_PtrSize)
    stringSize := 2 * (StrLen(message) + 1)

    NumPut("Ptr", stringSize, "Ptr", StrPtr(message), stringBuffer, A_PtrSize)

    if (SendMessage(MESSAGE_VAL, 0, stringBuffer,, MAINNAME,,,, waitTime) != 0) {
        ErrorMsg(
            (
                "
                Did not recieve confirmation from 
                " MAINNAME " within " . toString(waitTime) . "ms
                "
            ),
            true
        )
    }
}

; sends full message to main, including header & footer
;  list - each individual word to send to main
;
; returns null
sendListToMain(list) {
    list := toArray(list)
    
    sendMessageToMain(MESSAGE_START)

    for item in list {
        sendMessageToMain(item)
    }

    sendMessageToMain(MESSAGE_END)
}

; recieves a message bookended by MESSAGE_START and MESSAGE_END and runs whatever functions
; should run when a specific message is recieved
;  parameters are default for a function called by OnMessage
;
; returns null
getMessage(wParam, lParam, msg, hwnd) {
    global MESSAGE_ENABLE
    global MESSAGE_DATA

    stringAddress := NumGet(lParam, (2 * A_PtrSize), "Ptr")
    messageData := StrGet(stringAddress)

    if (messageData = MESSAGE_START) {
        MESSAGE_ENABLE := true
    }
    else if (MESSAGE_ENABLE) {
        if (messageData = MESSAGE_END) {
            MESSAGE_ENABLE := false

            retVal := MESSAGE_DATA
            MESSAGE_DATA := []

            return retVal
        }
        else {
            MESSAGE_DATA.Push(messageData)
        }
    }

    return []
}