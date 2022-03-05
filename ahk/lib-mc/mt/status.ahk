global MT_CHR_SIZE := 1     ; used for boolean
global MT_NUM_SIZE := 4     ; used for ints/floats
global MT_KEY_SIZE := 128   ; used for keys/names
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

    ; support for up to 32 hotkeys
    currHotkeys: MT_KEY_SIZE * 64,
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
                val := StrGet(ptrOffset + (32 * MT_KEY_SIZE), MT_KEY_SIZE)

                if (key = "") {
                    break
                }

                retMap[key] := val
                ptrOffset += MT_KEY_SIZE
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
            keys := []
            vals := []

            for key, val in newVal {
                keys.Push(key)
                vals.Push(val)
            }

            loop 32 {
                if (A_Index > keys.Length) {
                    StrPut("", ptrOffset, MT_KEY_SIZE)
                    ptrOffset += MT_KEY_SIZE
                }
                else {
                    StrPut(keys[A_Index], ptrOffset, MT_KEY_SIZE)
                    StrPut(vals[A_Index], ptrOffset + (32 * MT_KEY_SIZE), MT_KEY_SIZE)
                    ptrOffset += MT_KEY_SIZE
                }
            }
    }
}