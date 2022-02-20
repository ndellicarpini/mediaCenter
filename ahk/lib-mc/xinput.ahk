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

xInitBuffer(maxControllers) {
    return Buffer(16 * maxControllers, 0)
}

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

xCheckStatus(toCheck, port, ptr) {
    statusData := Buffer(16)
    loop 2 {
        NumPut("UInt64", NumGet(ptr + (port * 16) + (8 * (A_Index - 1)), 0, "UInt64")
        , statusData.Ptr + (8 * (A_Index - 1)), 0)
    }

    if (statusData = 0) {
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
            MsgBox(item)
            retVal := retVal & xCheckAxis(statusData, item)
        }
    }

    retVal := retVal & (((buttons & NumGet(statusData, xButtons.offset, xButtons.type)) > 0) ? true : false)
    return retVal
}

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


    if (InStr(remainingChars, ">") && currValue > value) {
        return true
    }
    else if (InStr(remainingChars, "<") && currValue < value) {
        return true
    }
    else if (InStr(remainingChars, "=") && currValue = value) {
        return true
    }

    return false
}