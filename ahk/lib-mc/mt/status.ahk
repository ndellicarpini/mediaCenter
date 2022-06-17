global MT_CHR_SIZE := 1     ; used for boolean
global MT_NUM_SIZE := 4     ; used for ints/floats
global MT_KEY_SIZE := 256   ; used for keys/names
global MT_STR_SIZE := 2048  ; used for strings

; keep info about the status as a global include so that multiple threads know
; how to access the status buffer
; 
; TODO - think about DefineProps getters/setter
global MT_STATUS_KEYS := {
    pause: MT_CHR_SIZE,
    suspendScript: MT_CHR_SIZE,
    kbmmode: MT_CHR_SIZE,
    currProgram: MT_KEY_SIZE,
    loadShow: MT_CHR_SIZE,
    loadText: MT_STR_SIZE,
    errorShow: MT_CHR_SIZE,
    errorHwnd: MT_NUM_SIZE,
    currGui: MT_KEY_SIZE,
    internalMessage: MT_KEY_SIZE,
    buttonTime: MT_NUM_SIZE,

    ; support for up to ~32 hotkeys
    currHotkeys: MT_KEY_SIZE * 256,
}

; creates the status buffer based on the data in MT_STATUS_KEYS
;
; returns status buffer
statusInitBuffer() {
    totalSize := 0
    
    for key in MT_STATUS_KEYS.OwnProps() {
        totalSize += MT_STATUS_KEYS.%key%
    }

    return Buffer(totalSize, 0)
}

; calculates the requested param's offset from buffer ptr
;  param - param to get offset of
;  ptr - base ptr of status buffer (if blank will default to globalStatus)
;
; returns ptr offset
calcStatusPtrOffset(param, ptr) {
    global globalStatus

    ptrOffset := ptr
    if (ptr = "") {
        ptrOffset := globalStatus
    }

    for key in MT_STATUS_KEYS.OwnProps() {
        if (key = param) {
            return ptrOffset
        }

        ptrOffset += MT_STATUS_KEYS.%key%
    }
}

; gets the requested param
;  param - requested param
;  ptr - base ptr of status buffer (if blank will default to globalStatus)
;
; returns param
getStatusParam(param, ptr := "") {
    switch param {
        case "pause":  
            return NumGet(calcStatusPtrOffset(param, ptr), 0, "UChar")
        case "suspendScript": 
            return NumGet(calcStatusPtrOffset(param, ptr), 0, "UChar") 
        case "kbmmode":  
            return NumGet(calcStatusPtrOffset(param, ptr), 0, "UChar")       
        case "currProgram": 
            return StrGet(calcStatusPtrOffset(param, ptr), MT_KEY_SIZE)    
        case "loadShow":   
            return NumGet(calcStatusPtrOffset(param, ptr), 0, "UChar")     
        case "loadText":
            return StrGet(calcStatusPtrOffset(param, ptr), MT_STR_SIZE)      
        case "errorShow": 
            return NumGet(calcStatusPtrOffset(param, ptr), 0, "UChar")      
        case "errorHwnd":  
            return NumGet(calcStatusPtrOffset(param, ptr), 0, "UInt")     
        case "buttonTime":  
            return NumGet(calcStatusPtrOffset(param, ptr), 0, "UInt")         
        case "currGui": 
            return StrGet(calcStatusPtrOffset(param, ptr), MT_KEY_SIZE)        
        case "internalMessage": 
            return StrGet(calcStatusPtrOffset(param, ptr), MT_KEY_SIZE)
        case "currHotkeys":
            ptrOffset := calcStatusPtrOffset(param, ptr)

            retMap := Map()
            loop 32 {
                key := StrGet(ptrOffset, MT_KEY_SIZE)
                valString := StrGet(ptrOffset + MT_KEY_SIZE, (MT_KEY_SIZE * 7))

                if (key = "") {
                    break
                }

                tempArr := StrSplit(valString, "{|}")
                val := Map()

                loop tempArr.Length {
                    if (tempArr[A_Index] = "DOWN") {
                        val["down"] := Trim(tempArr[A_Index + 1])
                    }
                    else if (tempArr[A_Index] = "UP") {
                        val["up"] := Trim(tempArr[A_Index + 1])
                    }
                    else if (tempArr[A_Index] = "TIME") {
                        val["time"] := Trim(tempArr[A_Index + 1])
                    }
                }

                retMap[key] := val

                ptrOffset += (MT_KEY_SIZE * 8)
            }

            return retMap
    }
}

; sets the requested param
;  param - requested param
;  newVal - new val to save as param
;  ptr - base ptr of status buffer (if blank will default to globalStatus)
;
; returns null
setStatusParam(param, newVal, ptr := "") {
    switch param {
        case "pause":  
            NumPut("UChar", newVal, calcStatusPtrOffset(param, ptr))
        case "suspendScript": 
            NumPut("UChar", newVal, calcStatusPtrOffset(param, ptr))
        case "kbmmode":  
            NumPut("UChar", newVal, calcStatusPtrOffset(param, ptr))
        case "currProgram": 
            StrPut(newVal, calcStatusPtrOffset(param, ptr), MT_KEY_SIZE)
        case "loadShow":   
            NumPut("UChar", newVal, calcStatusPtrOffset(param, ptr))     
        case "loadText":
            StrPut(newVal, calcStatusPtrOffset(param, ptr), MT_STR_SIZE)
        case "errorShow": 
            NumPut("UChar", newVal, calcStatusPtrOffset(param, ptr))      
        case "errorHwnd":  
            NumPut("UInt", newVal, calcStatusPtrOffset(param, ptr))      
        case "buttonTime":  
            NumPut("UInt", newVal, calcStatusPtrOffset(param, ptr))         
        case "currGui": 
            StrPut(newVal, calcStatusPtrOffset(param, ptr), MT_KEY_SIZE)  
        case "internalMessage": 
            StrPut(newVal, calcStatusPtrOffset(param, ptr), MT_KEY_SIZE)
        case "currHotkeys":
            ptrOffset := calcStatusPtrOffset(param, ptr)

            HOTKEY_SIZE := MT_KEY_SIZE * 8

            keys := []
            vals := []

            for key, val in newVal {
                keys.Push(key)
                vals.Push(val)
            }

            loop 32 {
                down := " "
                up   := " "
                time := " "
                
                if (A_Index > keys.Length) {
                    StrPut("", ptrOffset, HOTKEY_SIZE)
                    ptrOffset += HOTKEY_SIZE
                }
                else {
                    StrPut(keys[A_Index], ptrOffset, MT_KEY_SIZE)

                    if (IsObject(vals[A_Index])) {
                        for key, value in vals[A_Index] {
                            if (StrLower(key) = "down") {
                                down := value
                            }
                            else if (StrLower(key) = "up") {
                                up := value
                            }
                            else if (StrLower(key) = "time") {
                                time := value
                            }
                        }
                    }
                    else {
                        down := vals[A_Index]
                    }
                    
                    StrPut("{|}DOWN{|}" . down . "{|}UP{|}" . up . "{|}TIME{|}" . time . "{|}"
                        , ptrOffset + MT_KEY_SIZE, (MT_KEY_SIZE * 7))
                    
                    ptrOffset += HOTKEY_SIZE
                }
            }
    }
}

; whether or not important status fields have been updated
; ~~~~~~~~~~~~~~~~~~~ isn't it lovely ~~~~~~~~~~~~~~~~~~~~
;
; returns true if the status has been updated
statusUpdated() {
    static prevPause         := getStatusParam("pause")
    static prevSuspendScript := getStatusParam("suspendScript")
    static prevKbmmode       := getStatusParam("kbmmode")
    static prevCurrProgram   := getStatusParam("currProgram")
    static prevLoadShow      := getStatusParam("loadShow")
    static prevLoadText      := getStatusParam("loadText")
    static prevErrorShow     := getStatusParam("errorShow")
    static prevErrorHwnd     := getStatusParam("errorHwnd")
    static prevCurrGui       := getStatusParam("currGui")

    currPause         := getStatusParam("pause")
    currSuspendScript := getStatusParam("suspendScript")
    currKbmmode       := getStatusParam("kbmmode")
    currCurrProgram   := getStatusParam("currProgram")
    currLoadShow      := getStatusParam("loadShow")
    currLoadText      := getStatusParam("loadText")
    currErrorShow     := getStatusParam("errorShow")
    currErrorHwnd     := getStatusParam("errorHwnd")
    currCurrGui       := getStatusParam("currGui")

    if (prevPause != currPause || prevSuspendScript != currSuspendScript || prevKbmmode != currKbmmode || prevCurrProgram != currCurrProgram
        || prevLoadShow != currLoadShow || prevLoadText != currLoadText || prevErrorShow != currErrorShow || prevErrorHwnd != currErrorHwnd
        || prevCurrGui != currCurrGui) {
            
        prevPause         := currPause
        prevSuspendScript := currSuspendScript
        prevKbmmode       := currKbmmode
        prevCurrProgram   := currCurrProgram
        prevLoadShow      := currLoadShow
        prevLoadText      := currLoadText
        prevErrorShow     := currErrorShow
        prevErrorHwnd     := currErrorHwnd
        prevCurrGui       := currCurrGui

        return true
    } 

    return false
}