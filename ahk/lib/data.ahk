; creates a backup of status & saves it to backup directory
;  status - status obj to backup
;
; returns null
statusBackup() {
    global globalRunning
    global globalStatus

    backup := Map()

    for key, value in globalStatus {    
        ; don't backup input buffer   
        if (key = "input") {
            backup[key] := Map()
            for key2, value2 in globalStatus[key] {
                if (key2 != "buffer") {
                    backup[key][key2] := value2
                }
            }
        }
        else {
            backup[key] := globalStatus[key]
        }
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
    global globalPrograms

    if (!FileExist("data\backup.bin")) {
        return
    }

    backup := ObjLoad("data\backup.bin")
    
    for key, value in backup {
        if (key = "globalRunning") {
            for name, attr in backup["globalRunning"] {
                if (!globalPrograms.Has(name)) {
                    continue
                }

                ; clean attr so changes in configs workp
                cleanAttr := Map()
                for key2, value2 in attr {
                    if (!globalPrograms[name].Has(key2)) {
                        cleanAttr[key2] := value2
                    }
                }

                if (cleanAttr.Has("console")) {
                    createConsole([cleanAttr["console"], cleanAttr["rom"]], false, false, cleanAttr)
                }
                else {
                    params := [name]
                    if (cleanAttr["_launchArgs"].Length > 0) {
                        params.Push(((IsObject(cleanAttr["_launchArgs"])) ? cleanAttr["_launchArgs"] : [cleanAttr["_launchArgs"]])*)
                    }

                    createProgram(params, false, false, cleanAttr)
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

    static prevSuspendScript   := globalStatus["suspendScript"]
    static prevKbmmode         := globalStatus["kbmmode"]
    static prevDesktopmode     := globalStatus["desktopmode"]
    static prevCurrProgramID   := globalStatus["currProgram"]["id"]
    static prevCurrProgramEXE  := globalStatus["currProgram"]["exe"]
    static prevCurrProgramHWND := globalStatus["currProgram"]["hwnd"]
    static prevCurrGui         := globalStatus["currGui"]
    static prevCurrOverlay     := globalStatus["currOverlay"]
    static prevLoadShow        := globalStatus["loadscreen"]["show"]
    static prevLoadText        := globalStatus["loadscreen"]["text"]
    static prevLoadEnable      := globalStatus["loadscreen"]["enable"]
    static prevLoadOverride    := globalStatus["loadscreen"]["overrideWNDW"]

    currSuspendScript   := globalStatus["suspendScript"]
    currKbmmode         := globalStatus["kbmmode"]
    currDesktopmode     := globalStatus["desktopmode"]
    currCurrProgramID   := globalStatus["currProgram"]["id"]
    currCurrProgramEXE  := globalStatus["currProgram"]["exe"]
    currCurrProgramHWND := globalStatus["currProgram"]["hwnd"]
    currCurrGui         := globalStatus["currGui"]
    currCurrOverlay     := globalStatus["currOverlay"]
    currLoadShow        := globalStatus["loadscreen"]["show"]
    currLoadText        := globalStatus["loadscreen"]["text"]
    currLoadEnable      := globalStatus["loadscreen"]["enable"]
    currLoadOverride    := globalStatus["loadscreen"]["overrideWNDW"]

    if (prevSuspendScript != currSuspendScript || prevKbmmode != currKbmmode || prevDesktopmode != currDesktopmode 
        || prevCurrProgramID != currCurrProgramID || prevCurrProgramEXE != currCurrProgramEXE || prevCurrProgramHWND != currCurrProgramHWND
        || prevLoadShow != currLoadShow || prevLoadText != currLoadText || prevLoadEnable != currLoadEnable 
        || prevLoadOverride != currLoadOverride || prevCurrGui != currCurrGui || prevCurrOverlay != currCurrOverlay) {
            
        prevSuspendScript   := currSuspendScript
        prevKbmmode         := currKbmmode
        prevDesktopmode     := currDesktopmode
        prevCurrProgramID   := currCurrProgramID
        prevCurrProgramEXE  := currCurrProgramEXE
        prevCurrProgramHWND := currCurrProgramHWND
        prevLoadShow        := currLoadShow
        prevLoadText        := currLoadText
        prevLoadEnable      := currLoadEnable
        prevLoadOverride    := currLoadOverride
        prevCurrGui         := currCurrGui
        prevCurrOverlay     := currCurrOverlay

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
    global MONITOR_X
    global MONITOR_Y
    global MONITOR_W
    global MONITOR_H

    if (!DirExist("data\thumbnails\")) {
        DirCreate("data\thumbnails\")
    }

    imgPath := expandDir(validateDir((overridePath != "") ? overridePath : "data\thumbnails")) . name . ".png"

    try {
        compatibleDC := CreateCompatibleDC()
        screenDC     := GetDC()
        
        dibsBuffer := Buffer(40, 0)
        NumPut("UInt", 40, dibsBuffer.Ptr, 0)
        NumPut("UInt", MONITOR_W, dibsBuffer.Ptr, 4)
        NumPut("UInt", MONITOR_H, dibsBuffer.Ptr, 8)
        NumPut("UShort", 1, dibsBuffer.Ptr, 12)
        NumPut("UShort", 32, dibsBuffer.Ptr, 14)
        NumPut("UInt", 0, dibsBuffer.Ptr, 16)
    
        ppvBits := 0
        dibsSection := DllCall("CreateDIBSection", "UPtr", compatibleDC, "UPtr", dibsBuffer.Ptr, "UInt", 0, "UPtr*", &ppvBits, "UPtr", 0, "UInt", 0, "UPtr")
        gdiObject   := DllCall("SelectObject", "UPtr", compatibleDC, "UPtr", dibsSection)
    
        DllCall("gdi32\BitBlt", "UPtr", compatibleDC, "Int", 0, "Int", 0, "Int", MONITOR_W, "Int", MONITOR_H, "UPtr", screenDC, "Int", MONITOR_X, "Int", MONITOR_Y, "UInt", 0x00CC0020)
    
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
