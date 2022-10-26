class Input {
    pluginID := ""
    pluginPort := -1
    name := ""

    connected := false
    vibrating := false

    ; connectionType
    ;  -1 -> unknown
    ;   0 -> wired
    ;   1 -> battery
    connectionType := -1

    ; valid range 0 -> 1
    batteryLevel := 0

    initResults := Map()

    ; state of input buttons/axis
    buttons := []
    axis := Map()

    __New(initResults, pluginPort, inputConfigRef) {
        inputConfig := ObjDeepClone(inputConfigRef)
        
        this.pluginID := inputConfig["id"]
        this.pluginPort := pluginPort

        this.name := (inputConfig.Has("name")) ? inputConfig["name"] : this.name

        this.initResults := initResults
        
        this.initDevice()
    }

    ; this should only run once to intialize the controller port instance (beginnning of script)
    initDevice() { 
        
    } 

    ; this should only run once to remove the controller port instance (end of script)
    destroyDevice() {

    }

    getStatus() {
        return Map("buttons", [], "axis", Map())
    }

    checkConnectionType() {
        return this.connectionType
    }

    checkBatteryLevel() { 
        return this.batteryLevel
    }

    startVibration() {

    }

    stopVibration() {

    }
}

inputCheckStatus(hotkeys, statusResult) {
    hotkeyArr := toArray(hotkeys)

    retVal := true
    for key in hotkeyArr {
        retVal := retVal && (inArray(key, statusResult["buttons"]) || inputCompareAxis(key, statusResult))
    }

    return retVal
}

inputCompareAxis(axisComparison, statusResult) {
    getAxisVal(axis) {
        for key, value in statusResult["axis"] {
            if (StrLower(axis) = StrLower(key)) {
                return value
            }
        }

        return 0
    }

    if (InStr(axisComparison, ">")) {
        if (InStr(axisComparison, ">=")) {
            compareArr := StrSplit(axisComparison, ">=")
            return (getAxisVal(compareArr[1]) >= Float(compareArr[2]))
        }
        else {
            compareArr := StrSplit(axisComparison, ">")
            return (getAxisVal(compareArr[1]) > Float(compareArr[2]))
        }
    }
    else if (InStr(axisComparison, "<")) {
        if (InStr(axisComparison, "<=")) {
            compareArr := StrSplit(axisComparison, "<=")
            return (getAxisVal(compareArr[1]) <= Float(compareArr[2]))
        }
        else {
            compareArr := StrSplit(axisComparison, "<")
            return (getAxisVal(compareArr[1]) < Float(compareArr[2]))
        }
    }
    else if (InStr(axisComparison, "=")) {
        compareArr := StrSplit(axisComparison, "=")
        return (getAxisVal(compareArr[1]) = Float(compareArr[2]))
    }

    return false
}