global MT_CHR_SIZE := 1     ; used for boolean
global MT_NUM_SIZE := 4     ; used for ints/floats
global MT_KEY_SIZE := 128   ; used for keys/names
global MT_STR_SIZE := 2048  ; used for strings

; TODO 
; - refactor threads into just controller & hotkeys
; - maybe create individual thread for each controller?
; - move programThread into main
;   - share hotkeys as part of status
;   - current gui as part of status
;   - create guis in main

statusKeys := [
    { k: "pause",            s: MT_CHR_SIZE }
    { k: "suspendScript",    s: MT_CHR_SIZE }
    { k: "kbmmode",          s: MT_CHR_SIZE }
    { k: "currProgram",      s: MT_KEY_SIZE }
    { k: "overrideProgram",  s: MT_KEY_SIZE }
    { k: "loadShow",         s: MT_CHR_SIZE }
    { k: "loadText",         s: MT_STR_SIZE }
    { k: "errorShow",        s: MT_CHR_SIZE }
    { k: "errorHwnd",        s: MT_NUM_SIZE }
    { k: "currHotkeys",      s: (64 * 16) }
    { k: "currGui",          s: MT_KEY_SIZE }
]

calcStatusSize() {
    totalSize := 0
    
    for item in statusKeys {
        totalSize += item.s
    }

    return totalSize
}

calcStatusPtrOffset(param, ptr) {
    ptrOffset := ptr

    for item in statusKeys {
        if (item.k = param) {
            return ptrOffset
        }

        ptrOffset += item.s
    }
}

getStatusParam(param, ptr) {
    switch param {
        case "pause":  
            return NumGet(calcStatusPtrOffset(param, ptr), 0, "UChar")
        case "suspendScript": 
            return NumGet(calcStatusPtrOffset(param, ptr), 0, "UChar") 
        case "kbmmode":  
            return NumGet(calcStatusPtrOffset(param, ptr), 0, "UChar")       
        case "currProgram": 
            return StrGet(calcStatusPtrOffset(param, ptr), MT_KEY_SIZE)    
        case "overrideProgram": 
            return StrGet(calcStatusPtrOffset(param, ptr), MT_KEY_SIZE)
        case "loadShow":   
            return NumGet(calcStatusPtrOffset(param, ptr), 0, "UChar")     
        case "loadText":
            return StrGet(calcStatusPtrOffset(param, ptr), MT_STR_SIZE)      
        case "errorShow": 
            return NumGet(calcStatusPtrOffset(param, ptr), 0, "UChar")      
        case "errorHwnd":  
            return NumGet(calcStatusPtrOffset(param, ptr), 0, "UInt")         
        case "currGui": 
            return StrGet(calcStatusPtrOffset(param, ptr), MT_KEY_SIZE)
        case "currHotkeys":
            ptrOffset := calcStatusPtrOffset(param, ptr)
            retArr := []
            
            loop 64 {
                retArr.Push(StrGet(ptrOffset, 16, "CP0"))
                ptrOffset += 16
            }

            return retArr
    }
}

setStatusParam(param, newVal, buf) {
    switch param {
        case "pause":  
            NumPut("UChar", newVal, calcStatusPtrOffset(param, ptr))
        case "suspendScript": 
            NumPut("UChar", newVal, calcStatusPtrOffset(param, ptr))
        case "kbmmode":  
            NumPut("UChar", newVal, calcStatusPtrOffset(param, ptr))
        case "currProgram": 
            StrPut(newVal, calcStatusPtrOffset(param, ptr), MT_KEY_SIZE)
        case "overrideProgram": 
            StrPut(newVal, calcStatusPtrOffset(param, ptr), MT_KEY_SIZE)
        case "loadShow":   
            NumPut("UChar", newVal, calcStatusPtrOffset(param, ptr))     
        case "loadText":
            StrPut(newVal, calcStatusPtrOffset(param, ptr), MT_STR_SIZE)
        case "errorShow": 
            NumPut("UChar", newVal, calcStatusPtrOffset(param, ptr))      
        case "errorHwnd":  
            NumPut("UInt", newVal, calcStatusPtrOffset(param, ptr))         
        case "currGui": 
            StrPut(newVal, calcStatusPtrOffset(param, ptr), MT_KEY_SIZE)
        case "currHotkeys":
            ptrOffset := calcStatusPtrOffset(param, ptr)
            newVal := toArray(newVal)
            loop newVal.Length {
                StrPut(newVal[A_Index], ptrOffset, 16, "CP0")
                ptrOffset += 16
            }
    }
}