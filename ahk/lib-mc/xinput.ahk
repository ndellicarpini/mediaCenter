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
    return Buffer(18 * maxControllers, 0)
}

; gets the controller button status
;  maxControllers - max number of controllers supported
;  getStatusPtr - ptr to dll function get button status
;
; returns buffer w/ status data
xGetStatus(maxControllers, getStatusPtr) {
    retData := []

    loop maxControllers {
        xBuf := Buffer(16, 0)
        xResult := DllCall(getStatusPtr, "UInt", (A_Index - 1), "Ptr", xBuf.Ptr)

        if (xResult = 1167) {
            retData.Push(Buffer(16, 0))
        }
        else {
            retData.Push(xBuf)
        }
    }

    return retData
}

; gets the controller battery status
;  maxControllers - max number of controllers supported
;  getBatteryPtr - ptr to dll function get button status
;
; returns battery status
xGetBattery(maxControllers, getBatteryPtr) {
    retData := []

    loop maxControllers {
        xBuf := Buffer(8, 0)
        xResult := DllCall(getBatteryPtr, "UInt", (A_Index - 1), "UChar", 0, "UInt", xBuf.Ptr)

        if (xResult = 1167) {
            retData.Push(255)
        }
        else {
            retData.Push(NumGet(xBuf.Ptr, 1, "UChar"))
        }
    }

    return retData
}

; enables the full vibration force on the controller
;  maxControllers - max number of controllers supported
;  setVibePtr - ptr to dll function set vibration status
;  currVibe - array of length maxControllers that has prev vibration status
;  ptr - ptr to controller data to check
;
; returns array of new vibration status
xSetVibration(maxControllers, setVibePtr, currVibe, ptr) {
    newVibe := []
    loop maxControllers {
        controllerVibe := NumGet(ptr + ((A_Index - 1) * 18), 0, "UChar")
        if (controllerVibe != currVibe[A_Index]) {
            DllCall(setVibePtr, "UInt", (A_Index - 1), "UInt*", (controllerVibe) ? 65535|65535<<16 : 0)
        }

        newVibe.Push(controllerVibe)
    }

    return newVibe
}

; sets the appropriate value in globalControllers to enable the vibration
;  port - controller port to enable vibration on
;  ptr - ptr to controller data to check
;
; returns null
xEnableVibration(port, ptr) {
    NumPut("UChar", 1, ptr + (port * 18), 0)
}

; sets the appropriate value in globalControllers to disable the vibration
;  port - controller port to disable vibration on
;  ptr - ptr to controller data to check
;
; returns null
xDisableVibration(port, ptr) {
    NumPut("UChar", 0, ptr + (port * 18), 0)
}

; checks the buttons & axis of a specific controller, comparing them with current hotkeys
;  toCheck - current hotkeys to check
;  port - controller to check
;  ptr - ptr to controller data to check
; 
; returns boolean if hotkey status is fulfilled by controller status, or axis value
xCheckStatus(toCheck, port, ptr) {
    statusData := Buffer(16)
    loop 2 {
        NumPut("UInt64", NumGet(ptr + (port * 18) + 2 + (8 * (A_Index - 1)), 0, "UInt64")
        , statusData.Ptr + (8 * (A_Index - 1)), 0)
    }

    if (toCheck = "" || StrGet(ptr + (port * 18) + 2, 16) = "") {
        return false
    }

    retVal := true
    buttons := 0x000000
    for item in toArray(toCheck) {
        if (item = "") {
            continue
        }

        try {
            buttons := buttons | xButtons.%item%
        }
        catch {
            axisVal := xCheckAxis(statusData, item)

            if (Type(axisVal) != "String") {
                return axisVal
            }

            retVal := retVal & (axisVal = "true") ? true : false
        }
    }

    if (buttons != 0) {
        retVal := retVal & ((buttons & NumGet(statusData, xButtons.offset, xButtons.type) > 0) ? true : false)
    }

    return retVal
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
        return "true"
    }
    else if (InStr(comparison, "<") && currValue < value) {
        return "true"
    }
    else if (InStr(comparison, "=") && currValue = value) {
        return "true"
    }

    return "false"
}