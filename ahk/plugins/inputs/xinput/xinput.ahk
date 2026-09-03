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

    static checkBlockingBatteryLevels() {
        ; loop through and find Bluetooth controllers
        allDeviceText := RunPowershell("(Get-PnpDevice -Class 'Bluetooth' -FriendlyName '*xbox*' | Get-PnpDeviceProperty | Select InstanceId,KeyName,Data)")
        allDeviceProperties := StrSplit(allDeviceText, "`n") 

        allDevices := Map()
        propPosArr := []
        for (item in allDeviceProperties) {
            if (Trim(item, " `t`r`n") = "") {
                continue
            }

            if (propPosArr.Length = 0) {
                propArr := StrSplit(item, "     ").Map(val => Trim(val, " `t`r`n")).Filter(val => val != "")
                for prop in propArr {
                    propPosArr.Push(InStr(item, prop))
                }
                continue
            }

            propArr := [
                SubStr(item, propPosArr[1], propPosArr[2] - 1),
                SubStr(item, propPosArr[2], propPosArr[3] - propPosArr[2]),
                SubStr(item, propPosArr[3]),
            ]

            if (!allDevices.Has(propArr[1])) {
                allDevices[propArr[1]] := Map()
            }

            cleanValue := Trim(propArr[3], " `t`r`n")
            if (cleanValue = "") {
                continue
            }

            key := Trim(StrLower(propArr[2]))
            if (key = "devpkey_name") {
                allDevices[propArr[1]]["name"] := cleanValue
            }
            else if (key = "devpkey_devicecontainer_category") {
                allDevices[propArr[1]]["gamepad"] := (StrLower(cleanValue) = "{input.gaming.gamepad}")
            }
            else if (key = "devpkey_bluetooth_lastconnectedtime") {
                timeStr := cleanValue

                formattedStr := ""
                allComponents := StrSplit(timeStr, " ")
                isPM := (StrLower(Trim(allComponents[3])) = "pm")
                dateComponents := StrSplit(allComponents[1], "/")
                timeComponents := StrSplit(allComponents[2], ":")

                formattedStr .= dateComponents[3]
                formattedStr .= Format("{:02}", Integer(dateComponents[1]))
                formattedStr .= Format("{:02}", Integer(dateComponents[2]))

                hours := Integer(timeComponents[1])
                if (hours = 12) {
                    hours := isPM ? 12 : 0
                }
                else if (isPM) {
                    hours += 12
                }

                formattedStr .= Format("{:02}", hours)
                formattedStr .= Format("{:02}", Integer(timeComponents[2]))
                formattedStr .= Format("{:02}", Integer(timeComponents[3]))

                ; the offset is in the wrong direction for connected time?
                allDevices[propArr[1]]["time"] := GetLocaleUnixTimestep(formattedStr) - GetUTCOffset()
            }
            else if (key = "{83da6326-97a6-4088-9453-a1923f573b29} 15") {
                allDevices[propArr[1]]["connected"] := (StrLower(cleanValue) = "true")
            }
            else if (key = "{104ea319-6ee2-4701-bd47-8ddbf425bbe5} 2") {
                allDevices[propArr[1]]["battery"] := cleanValue
            }
        }

        currBTGamepads := globalInputStatus["xinput"]
            .Filter((val) => val["connected"] && val["connectionType"] = 2)
            .Sort((a, b) => a["pluginPort"] - b["pluginPort"])

        portBatteries := Map()
        bruh := Map()
        for _, gamepad in allDevices {
            if (!gamepad.Has("gamepad") || !gamepad["gamepad"] 
                || !gamepad.Has("connected") || !gamepad["connected"] 
                || !gamepad.Has("name") || !InStr(StrLower(gamepad["name"]), "xbox")) {

                continue
            }

            minDiff := 2147483640
            minPort := -1
            for device in currBTGamepads {
                if portBatteries.Has(String(device["pluginPort"])){
                    continue
                }

                currDiff := Abs(device["connectedTime"] - gamepad["time"])
                if (currDiff < minDiff) {
                    minDiff := currDiff
                    minPort := device["pluginPort"]
                }
            }

            portBatteries[String(minPort)] := Integer(gamepad["battery"]) / 100
        }

        return portBatteries
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

        if (xResult = 1167) {
            this.connected := false
            this.connectedTime := -1

            return Map("buttons", this.buttons, "axis", this.axis)
        }
        else {
            if (!this.connected) {
                this.connectedTime := GetLocaleUnixTimestep()
            }

            this.connected := true
        }
        

        ; CHECK BUTTONS
        buttonBuf := NumGet(xBuf.Ptr, 4, "UShort")
        this.buttons["A"]      := (buttonBuf & 0x1000) ? true : false
        this.buttons["B"]      := (buttonBuf & 0x2000) ? true : false 
        this.buttons["X"]      := (buttonBuf & 0x4000) ? true : false 
        this.buttons["Y"]      := (buttonBuf & 0x8000) ? true : false 
        this.buttons["LB"]     := (buttonBuf & 0x0100) ? true : false 
        this.buttons["RB"]     := (buttonBuf & 0x0200) ? true : false 
        this.buttons["SELECT"] := (buttonBuf & 0x0020) ? true : false
        this.buttons["START"]  := (buttonBuf & 0x0010) ? true : false
        this.buttons["LSB"]    := (buttonBuf & 0x0040) ? true : false
        this.buttons["RSB"]    := (buttonBuf & 0x0080) ? true : false
        this.buttons["DU"]     := (buttonBuf & 0x0001) ? true : false
        this.buttons["DD"]     := (buttonBuf & 0x0002) ? true : false 
        this.buttons["DL"]     := (buttonBuf & 0x0004) ? true : false 
        this.buttons["DR"]     := (buttonBuf & 0x0008) ? true : false 
        this.buttons["HOME"]   := (buttonBuf & 0x0400) ? true : false

        ; CHECK AXIS
        this.axis["LSX"] := NumGet(xBuf.Ptr, 8, "Short") / 32768 
        this.axis["LSY"] := NumGet(xBuf.Ptr, 10, "Short") / 32768
        this.axis["RSX"] := NumGet(xBuf.Ptr, 12, "Short") / 32768
        this.axis["RSY"] := NumGet(xBuf.Ptr, 14, "Short") / 32768
        this.axis["LT"]  := NumGet(xBuf.Ptr, 6, "UChar") / 255
        this.axis["RT"]  := NumGet(xBuf.Ptr, 7, "UChar") / 255

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

        ; wired
        if (connection = 1) {
            this.connectionType := 0
        }
        ; bluetooth
        else if (connection = 0) {
            this.connectionType := 2
        }
        ; wireless / "on-battery"
        else if (connection = 2 || connection = 3) {
            this.connectionType := 1
        }
        ; unknown
        else {
            this.connectionType := -1
        }

        this.batteryCheckBlocking := this.connectionType = 2 
        return this.connectionType
    }

    checkBatteryLevel() {
        global globalInputStatus

        xBuf := Buffer(2, 0)
        xResult := DllCall(this.initResults["getBatteryPtr"], "UInt", this.pluginPort, "UChar", 0, "UInt", xBuf.Ptr)

        if (this.batteryCheckBlocking || xResult = 1167) {
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