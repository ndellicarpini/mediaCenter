class XInputDevice extends Input {
    buttons := []
    axis := Map(
        "LT", 0,
        "RT", 0,
        "LSX", 0,
        "LSY", 0,
        "RSX", 0,
        "RSY", 0
    )

    initDevice() {
        this.getStatus()

        if (this.connected) {
            this.checkConnectionType()
            this.checkBatteryLevel()
        }
    }

    getStatus() {
        xBuf := Buffer(16, 0)
        xResult := DllCall(this.initResults["getStatusPtr"], "UInt", this.pluginPort, "Ptr", xBuf.Ptr)

        if (xResult = 1167) {
            this.connected := false
            this.buttons := []

            return Map("buttons", this.buttons, "axis", this.axis)
        }
        
        this.connected := true
        this.buttons := []

        ; CHECK BUTTONS
        buttonBuf := NumGet(xBuf.Ptr, 4, "UShort")
        if (buttonBuf & 0x0001) {
            this.buttons.Push("DU")
        }
        if (buttonBuf & 0x0002) {
            this.buttons.Push("DD")
        }
        if (buttonBuf & 0x0004) {
            this.buttons.Push("DL")
        }
        if (buttonBuf & 0x0008) {
            this.buttons.Push("DR")
        }
        if (buttonBuf & 0x1000) {
            this.buttons.Push("A")
        }
        if (buttonBuf & 0x2000) {
            this.buttons.Push("B")
        }
        if (buttonBuf & 0x4000) {
            this.buttons.Push("X")
        }
        if (buttonBuf & 0x8000) {
            this.buttons.Push("Y")
        }
        if (buttonBuf & 0x0100) {
            this.buttons.Push("LB")
        }
        if (buttonBuf & 0x0200) {
            this.buttons.Push("RB")
        }
        if (buttonBuf & 0x0040) {
            this.buttons.Push("LSB")
        }
        if (buttonBuf & 0x0080) {
            this.buttons.Push("RSB")
        }
        if (buttonBuf & 0x0020) {
            this.buttons.Push("SELECT")
        }
        if (buttonBuf & 0x0010) {
            this.buttons.Push("START")
        }
        if (buttonBuf & 0x0400) {
            this.buttons.Push("HOME")
        }

        ; CHECK AXIS
        this.axis["LT"]  := NumGet(xBuf.Ptr, 6, "UChar") / 255
        this.axis["RT"]  := NumGet(xBuf.Ptr, 7, "UChar") / 255
        this.axis["LSX"] := NumGet(xBuf.Ptr, 8, "Short") / 32768
        this.axis["LSY"] := NumGet(xBuf.Ptr, 10, "Short") / 32768
        this.axis["RSX"] := NumGet(xBuf.Ptr, 12, "Short") / 32768
        this.axis["RSY"] := NumGet(xBuf.Ptr, 14, "Short") / 32768

        return Map(
            "buttons", this.buttons,
            "axis", this.axis
        )
    }

    checkConnectionType() {
        xBuf := Buffer(2, 0)
        xResult := DllCall(this.initResults["getBatteryPtr"], "UInt", this.pluginPort, "UChar", 0, "UInt", xBuf.Ptr)

        if (xResult = 1167) {
            this.connectionType := -1
            return this.connectionType
        }

        connection := NumGet(xBuf.Ptr, 0, "UChar")  

        if (connection = 1) {
            this.connectionType := 0
        }
        else if (connection = 2 || connection = 3) {
            this.connectionType := 1
        }
        else {
            this.connectionType := -1
        }
             
        return this.connectionType
    }

    checkBatteryLevel() {
        xBuf := Buffer(2, 0)
        xResult := DllCall(this.initResults["getBatteryPtr"], "UInt", this.pluginPort, "UChar", 0, "UInt", xBuf.Ptr)

        if (xResult = 1167) {
            this.batteryLevel := 0
            return this.batteryLevel
        }

        battery := NumGet(xBuf.Ptr, 1, "UChar")  

        switch (battery) {
            case 0:
                this.batteryLevel := 0.05
            case 1:
                this.batteryLevel := 0.25
            case 2:
                this.batteryLevel := 0.8
            case 3:
                this.batteryLevel := 1
            default:
                this.batteryLevel := 0
        }

        return this.batteryLevel
    }

    startVibration() {
        return DllCall(this.initResults["setVibrationPtr"], "UInt", this.pluginPort, "UInt*", 65535|65535<<16)
    }

    stopVibration() {
        return DllCall(this.initResults["setVibrationPtr"], "UInt", this.pluginPort, "UInt*", 0)
    }
}

xInitialize() {
    xLibrary := dllLoadLib("xinput1_3.dll")

    xGetStatusPtr := DllCall('GetProcAddress', 'UInt', xLibrary, 'UInt', 100)
    xGetBatteryPtr := DllCall('GetProcAddress', 'UInt', xLibrary, 'AStr', 'XInputGetBatteryInformation')
    xSetVibrationPtr := DllCall('GetProcAddress', 'UInt', xLibrary, 'AStr', 'XInputSetState')

    return Map(
        "dllLibPtr", xLibrary,
        "getStatusPtr", xGetStatusPtr,
        "getBatteryPtr", xGetBatteryPtr,
        "setVibrationPtr", xSetVibrationPtr
    )
}

xDestroy() {
    global globalInputStatus

    xinputControllers := globalInputStatus["xinput"]
    if (xinputControllers.Length > 0) {
        dllFreeLib(xinputControllers[1]["initResults"]["dllLibPtr"])
    }
}