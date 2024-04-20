class XInputDevice extends Input {
    static initialize() {
        xLibrary := DllLoadLib("xinput1_4.dll")

        xGetStatusPtr := DllCall('GetProcAddress', 'UInt', xLibrary, 'UInt', 100, 'Ptr')
        xGetDeviceInfoPtr := DllCall('GetProcAddress', 'UInt', xLibrary, 'UInt', 108, 'Ptr')
        xGetBatteryPtr := DllCall('GetProcAddress', 'UInt', xLibrary, 'AStr', 'XInputGetBatteryInformation', 'Ptr')
        xSetVibrationPtr := DllCall('GetProcAddress', 'UInt', xLibrary, 'AStr', 'XInputSetState', 'Ptr')

        return Map(
            "dllLibPtr", xLibrary,
            "getStatusPtr", xGetStatusPtr,
            "getBatteryPtr", xGetBatteryPtr,
            "getDeviceInfoPtr", xGetDeviceInfoPtr,
            "setVibrationPtr", xSetVibrationPtr
        )
    }

    static destroy() {
        global globalInputStatus

        xinputControllers := globalInputStatus["xinput"]
        if (xinputControllers.Length > 0) {
            DllFreeLib(xinputControllers[1]["initResults"]["dllLibPtr"])
        }
    }

    initDevice() {
        this.getStatus()

        if (this.connected) {
            this.checkDeviceInfo()
            this.checkConnectionType()
            this.checkBatteryLevel()
        }
    }

    getStatus() {
        xBuf := Buffer(16, 0)
        xResult := DllCall(this.initResults["getStatusPtr"], "UInt", this.pluginPort, "Ptr", xBuf.Ptr)

        ; reset button statuses
        super.getStatus()

        if (xResult = 1167) {
            this.connected := false

            return Map("buttons", this.buttons, "axis", this.axis)
        }
        
        this.connected := true

        ; CHECK BUTTONS
        buttonBuf := NumGet(xBuf.Ptr, 4, "UShort")
        if (buttonBuf & 0x1000) { ; A
            this.buttons[1] := true 
        }
        if (buttonBuf & 0x2000) { ; B
            this.buttons[2] := true 
        }
        if (buttonBuf & 0x4000) { ; X
            this.buttons[3] := true 
        }
        if (buttonBuf & 0x8000) { ; Y
            this.buttons[4] := true 
        }
        if (buttonBuf & 0x0100) { ; LB
            this.buttons[5] := true 
        }
        if (buttonBuf & 0x0200) { ; RB
            this.buttons[6] := true 
        }
        if (buttonBuf & 0x0020) { ; SELECT
            this.buttons[7] := true
        }
        if (buttonBuf & 0x0010) { ; START
            this.buttons[8] := true
        }
        if (buttonBuf & 0x0040) { ; LSB
            this.buttons[9] := true
        }
        if (buttonBuf & 0x0080) { ; RSB
            this.buttons[10] := true
        }
        if (buttonBuf & 0x0001) { ; DU
            this.buttons[11] := true 
        }
        if (buttonBuf & 0x0002) { ; DD
            this.buttons[12] := true 
        }
        if (buttonBuf & 0x0004) { ; DL
            this.buttons[13] := true 
        }
        if (buttonBuf & 0x0008) { ; DR
            this.buttons[14] := true 
        }
        if (buttonBuf & 0x0400) { ; HOME
            this.buttons[15] := true
        }

        ; CHECK AXIS
        this.axis[1] := NumGet(xBuf.Ptr, 8, "Short") / 32768  ; LSX
        this.axis[2] := NumGet(xBuf.Ptr, 10, "Short") / 32768 ; LSY
        this.axis[3] := NumGet(xBuf.Ptr, 12, "Short") / 32768 ; RSX
        this.axis[4] := NumGet(xBuf.Ptr, 14, "Short") / 32768 ; RSY
        this.axis[5] := NumGet(xBuf.Ptr, 6, "UChar") / 255    ; LT
        this.axis[6] := NumGet(xBuf.Ptr, 7, "UChar") / 255    ; RT

        return Map("buttons", this.buttons, "axis", this.axis)
    }

    checkDeviceInfo() {
        xBuf := Buffer(30, 0)
        xResult := DllCall(this.initResults["getDeviceInfoPtr"], "UInt", 1, "UInt", this.pluginPort, "UInt", 0, "Ptr", xBuf.Ptr)
        if (xResult = 1167) {
            return
        }
        
        type := NumGet(xBuf.Ptr, 0, "UChar")
        subtype := NumGet(xBuf.Ptr, 1, "UChar")

        vendorID := NumGet(xBuf.Ptr, 20, "UShort")
        productID := NumGet(xBuf.Ptr, 22, "UShort")
        revisionID := NumGet(xBuf.Ptr, 24, "UShort")
        unknown1 := NumGet(xBuf.Ptr, 26, "UShort")
        unknown2 := NumGet(xBuf.Ptr, 28, "UShort")

        this.vendorID := vendorID
        this.productID := productID
        this.revisionID := revisionID

        this.name := getInputDeviceName(this.vendorID, this.productID)

        return Map(
            "name", this.name,
            "vendorID", this.vendorID,
            "productID", this.productID,
            "revisionID", this.revisionID
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