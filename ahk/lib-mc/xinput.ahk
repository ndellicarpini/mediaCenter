; BUFFER LAYOUT (PER CONTROLLER) (BYTES)
;  1 - enable/disable vibration status
;  1 - battery info
;  16 - controller button status

xButtons := {
    offset: 4,
    type: "UShort",

    DU:  0x0001,
    DD:  0x0002,
    DL:  0x0004,
    DR:  0x0008,

    A:   0x1000,
    B:   0x2000,
    X:   0x4000,
    Y:   0x8000,
    LB:  0x0100,
    RB:  0x0200,
    LSB: 0x0040,
    RSB: 0x0080,

    SELECT: 0x0020,
    START:  0x0010,
    HOME:   0x0400,
}

xAxis := {
    LT: {
        offset: 6,
        type: "UChar",
        max: 255
    },
    RT: {
        offset: 7,
        type: "UChar",
        max: 255
    },

    LSX: {
        offset: 8,
        type: "Short",
        max: 32768
    },
    LSY: {
        offset: 10,
        type: "Short",
        max: 32768
    },

    RSX: {
        offset: 12,
        type: "Short",
        max: 32768
    },
    RSY: {
        offset: 14,
        type: "Short",
        max: 32768
    },
}

; creates the buffer for xinput devices based on max controllers supported
;  maxControllers - max number of controllers suppoorted
;
; returns Buffer
xInitBuffer(maxControllers) {
    return Buffer(20 * maxControllers, 0)
}

; gets the controller button status
;  port - current controller to check
;  getStatusPtr - ptr to dll function get button status
;
; returns buffer w/ status data
xGetStatus(port, getStatusPtr) {
    xBuf := Buffer(16, 0)
    xResult := DllCall(getStatusPtr, "UInt", port, "Ptr", xBuf.Ptr)

    if (xResult = 1167) {
        return -1
    }
       
    return xBuf
}

; gets the controller battery status
;  port - current controller to check
;  getBatteryPtr - ptr to dll function get button status
;
; returns battery status
xGetBattery(port, getBatteryPtr) {
    xBuf := Buffer(2, 0)
    xResult := DllCall(getBatteryPtr, "UInt", port, "UChar", 0, "UInt", xBuf.Ptr)

    if (xResult = 1167) {
        return -1
    }

    return xBuf
}

; enables the full vibration force on the controller
;  port - current controller to check
;  setVibePtr - ptr to dll function set vibration status
;  controllerVibe - new requested vibration status
;
; returns array of new vibration status
xSetVibration(port, setVibePtr, controllerVibe) {
    DllCall(setVibePtr, "UInt", port, "UInt*", (controllerVibe) ? 65535|65535<<16 : 0)

    return controllerVibe
}

; gets the controller battery type
;  port - current controller to check
;  ptr - ptr to controller data to check
;
; returns battery type
xGetBatteryType(port, ptr) {
    return NumGet(ptr + (port * 20) + 1, 0, "UChar")
}

; gets the controller battery level
;  port - current controller to check
;  ptr - ptr to controller data to check
;
; returns battery level
xGetBatteryLevel(port, ptr) {
    level := NumGet(ptr + (port * 20) + 2, 0, "UChar")

    switch (level) {
        case 0:
            return 0
        case 1:
            return 0.2
        case 2:
            return 0.8
        case 3:
            return 1
    }
    
    return 0
}

; gets the controller connected status
;  port - current controller to check
;  ptr - ptr to controller data to check
;
; returns connected status
xGetConnected(port, ptr) {
    return NumGet(ptr + (port * 20), 0, "UChar")
}

; sets the appropriate value in globalControllers to enable the vibration
;  port - controller port to enable vibration on
;  ptr - ptr to controller data to check
;
; returns null
xEnableVibration(port, ptr) {
    NumPut("UChar", 1, ptr + (port * 20) + 3, 0)
}

; sets the appropriate value in globalControllers to disable the vibration
;  port - controller port to disable vibration on
;  ptr - ptr to controller data to check
;
; returns null
xDisableVibration(port, ptr) {
    NumPut("UChar", 0, ptr + (port * 20) + 3, 0)
}

; checks the buttons & axis of a specific controller, comparing them with current hotkeys
;  toCheck - current hotkeys to check
;  port - controller to check
;  ptr - ptr to controller data to check
; 
; returns boolean if hotkey status is fulfilled by controller status, or axis value
xCheckStatus(toCheck, port, ptr) {
    if (toCheck = "" || !xGetConnected(port, ptr)) {
        return false
    }

    checkArr := toArray(toCheck)
    ; if (!inArray("HOME", checkArr)) && xGetBatteryType(port, ptr) = 0) {
    ;     return false
    ; }

    statusData := Buffer(16)
    copyBufferData(ptr + (port * 20) + 4, statusData.Ptr, 16)

    retVal := true

    axisVal := true
    checkAxis := false
    buttons := 0x000000
    for item in checkArr {
        if (item = "") {
            continue
        }

        try {
            buttons := buttons | xButtons.%item%
        }
        catch {
            checkAxis := true
            axisVal := xCheckAxis(statusData, item)
        }
    }

    if (buttons = 0x000000) {
        return ((checkAxis) ? axisVal : false)
    }

    return ((checkAxis) ? axisVal : true) && (buttons = (buttons & NumGet(statusData, xButtons.offset, xButtons.type)))
}

; checks the axis of a specific controller
;  statusData - controller status buffer
;  axis - axis to check from hotkeys
; 
; returns boolean if axis is a comparison, otherwise returns axis value
xCheckAxis(statusData, axis) {
    currAxis := ""
    for key in xAxis.OwnProps() {
        if (InStr(axis, key)) {
            currAxis := key
            break
        }
    }

    if (currAxis = "") {
        ErrorMsg("Tried to get an axis that doesn't exist: " . axis, true)
    }

    if (currAxis = axis) {
        return NumGet(statusData, xAxis.%currAxis%.offset, xAxis.%currAxis%.type)
    }

    value := 0
    comparison := ""
    remainingChars := StrReplace(axis, currAxis, "")
    remainingCharArr := StrSplit(remainingChars)

    for char in remainingCharArr {
        try {
            value := Float(remainingChars)
            break
        }
        catch {
            comparison .= char
            remainingChars := SubStr(remainingChars, 2)
        }
    }

    if (remainingChars = "") {
        ErrorMsg("No value to compare axis to " . axis, true)
    }

    currValue := NumGet(statusData, xAxis.%currAxis%.offset, xAxis.%currAxis%.type) / xAxis.%currAxis%.max

    if (InStr(comparison, ">") && currValue > value) {
        return true
    }
    else if (InStr(comparison, "<") && currValue < value) {
        return true
    }
    else if (InStr(comparison, "=") && currValue = value) {
        return true
    }

    return false
}