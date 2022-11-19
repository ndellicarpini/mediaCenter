; creates a backup of status & saves it to backup directory
;  status - status obj to backup
;
; returns null
statusBackup() {
    global globalRunning
    global globalStatus

    backup := Map()

    for key, value in globalStatus {       
        backup[key] := globalStatus[key]
    }
    
    backup["globalRunning"] := Map()
    for key, value in globalRunning {
        attrMap := Map()
        for name, attr in value.OwnProps() {
            attrMap[name] := attr
        }

        backup["globalRunning"][key] := attrMap
    }

    backupFile := FileOpen("data\backup.bin", "w -rwd")
    backupFile.RawWrite(ObjDump(backup))
    backupFile.Close()
}

; restores status backup & returns proper status object
;  status - status obj to update with restored values
;  programs - program configs parsed in main
; 
; returns status updated with values from backup
statusRestore() {
    global globalStatus

    if (!FileExist("data\backup.bin")) {
        return
    }

    backup := ObjLoad("data\backup.bin")
    
    for key, value in backup {
        if (key = "globalRunning") {
            for name, attr in backup["globalRunning"] {
                if (attr.Has("console")) {
                    createConsole([attr["console"], attr["rom"]], false, false, attr)
                }
                else {
                    createProgram(name, false, false, attr)
                }
            }
        }
        else {
            globalStatus[key] := value
        }
    }
}

; whether or not important status fields have been updated
; ~~~~~~~~~~~~~~~~~~~ isn't it lovely ~~~~~~~~~~~~~~~~~~~~
;
; returns true if the status has been updated
statusUpdated() {
    global globalStatus

    static prevPause         := globalStatus["pause"]
    static prevSuspendScript := globalStatus["suspendScript"]
    static prevKbmmode       := globalStatus["kbmmode"]
    static prevDesktopmode   := globalStatus["desktopmode"]
    static prevCurrProgram   := globalStatus["currProgram"]
    static prevCurrGui       := globalStatus["currGui"]
    static prevLoadShow      := globalStatus["loadscreen"]["show"]
    static prevLoadText      := globalStatus["loadscreen"]["text"]
    static prevLoadEnable    := globalStatus["loadscreen"]["enable"]
    static prevLoadOverride  := globalStatus["loadscreen"]["overrideWNDW"]

    currPause         := globalStatus["pause"]
    currSuspendScript := globalStatus["suspendScript"]
    currKbmmode       := globalStatus["kbmmode"]
    currDesktopmode   := globalStatus["desktopmode"]
    currCurrProgram   := globalStatus["currProgram"]
    currCurrGui       := globalStatus["currGui"]
    currLoadShow      := globalStatus["loadscreen"]["show"]
    currLoadText      := globalStatus["loadscreen"]["text"]
    currLoadEnable    := globalStatus["loadscreen"]["enable"]
    currLoadOverride  := globalStatus["loadscreen"]["overrideWNDW"]

    if (prevPause != currPause || prevSuspendScript != currSuspendScript || prevKbmmode != currKbmmode || prevDesktopmode != currDesktopmode 
        || prevCurrProgram != currCurrProgram || prevLoadShow != currLoadShow || prevLoadText != currLoadText 
        || prevLoadEnable != currLoadEnable || prevLoadOverride != currLoadOverride || prevCurrGui != currCurrGui) {
            
        prevPause         := currPause
        prevSuspendScript := currSuspendScript
        prevKbmmode       := currKbmmode
        prevDesktopmode   := currDesktopmode
        prevCurrProgram   := currCurrProgram
        prevLoadShow      := currLoadShow
        prevLoadText      := currLoadText
        prevLoadEnable    := currLoadEnable
        prevLoadOverride  := currLoadOverride
        prevCurrGui       := currCurrGui

        return true
    } 

    return false
}

; takes a screenshot & saves it w/ the requested params
;  name - name of the file
;  overridePath - custom path to save image
;
; returns null
saveScreenshot(name, overridePath := "") {
    global MONITORX
    global MONITORY
    global MONITORW
    global MONITORH

    if (!DirExist("data\thumbnails\")) {
        DirCreate("data\thumbnails\")
    }

    imgPath := expandDir(validateDir((overridePath != "") ? overridePath : "data\thumbnails")) . name . ".png"

    try {
        compatibleDC := CreateCompatibleDC()
        screenDC     := GetDC()
        
        dibsBuffer := Buffer(40, 0)
        NumPut("UInt", 40, dibsBuffer.Ptr, 0)
        NumPut("UInt", MONITORW, dibsBuffer.Ptr, 4)
        NumPut("UInt", MONITORH, dibsBuffer.Ptr, 8)
        NumPut("UShort", 1, dibsBuffer.Ptr, 12)
        NumPut("UShort", 32, dibsBuffer.Ptr, 14)
        NumPut("UInt", 0, dibsBuffer.Ptr, 16)
    
        ppvBits := 0
        dibsSection := DllCall("CreateDIBSection", "UPtr", compatibleDC, "UPtr", dibsBuffer.Ptr, "UInt", 0, "UPtr*", &ppvBits, "UPtr", 0, "UInt", 0, "UPtr")
        gdiObject   := DllCall("SelectObject", "UPtr", compatibleDC, "UPtr", dibsSection)
    
        DllCall("gdi32\BitBlt", "UPtr", compatibleDC, "Int", 0, "Int", 0, "Int", MONITORW, "Int", MONITORH, "UPtr", screenDC, "Int", MONITORX, "Int", MONITORY, "UInt", 0x00CC0020)
    
        ReleaseDC(screenDC)
    
        screenBitmap := 0
        DllCall("GdiPlus\GdipCreateBitmapFromHBITMAP", "UPtr", dibsSection, "UPtr", 0, "UPtr*", &screenBitmap)
        DllCall("SelectObject", "UPtr", compatibleDC, "UPtr", gdiObject)
        DllCall("DeleteObject", "UPtr", dibsSection)
    
        encodeCount := 0
        encodeSize  := 0
        DllCall("GdiPlus\GdipGetImageEncodersSize", "UInt*", &encodeCount, "UInt*", &encodeSize)
    
        encodeBuffer := Buffer(encodeSize, 0)
        DllCall("GdiPlus\GdipGetImageEncoders", "UInt", encodeCount, "UInt", encodeSize, "UPtr", encodeBuffer.Ptr)
        DllCall("GdiPlus\GdipSaveImageToFile", "UPtr", screenBitmap, "UPtr", StrPtr(imgPath), "UPtr", encodeBuffer.Ptr + 416, "UInt", 0)
        DllCall("GdiPlus\GdipDisposeImage", "UPtr", screenBitmap)
    
        DeleteDC(compatibleDC)
        DeleteDC(screenDC)
    }
}
