class Controller {
    pluginID := ""
    pluginPort := -1
    name := ""

    connected := false
    ; connectionType
    ;  -1 -> unknown
    ;   0 -> wired
    ;   1 -> battery
    connectionType := -1

    ; valid range 0 -> 1
    batteryLevel := 0

    initResults := Map()

    ; state of controller buttons/axis
    buttons := []
    axis := Map()

    __New(initResults, pluginPort, controllerConfigRef) {
        controllerConfig := ObjDeepClone(controllerConfigRef)
        
        this.pluginID := controllerConfig["id"]
        this.pluginPort := pluginPort

        this.name := (controllerConfig.Has("name")) ? controllerConfig["name"] : this.name

        this.initResults := initResults
        
        this.initController()
    }

    ; SHOULD ONLY HAVE DO TO ONCE
    initController() { 
        
    } 
    ; SHOULD ONLY DO AT END OF SCRIPT
    destroyController() {

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

controllerCheckStatus(hotkeys, statusResult) {
    hotkeyArr := toArray(hotkeys)

    retVal := true
    for key in hotkeyArr {
        retVal := retVal && (inArray(key, statusResult["buttons"]) || controllerCompareAxis(key, statusResult))
    }

    return retVal
}

controllerCompareAxis(axisComparison, statusResult) {
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
            compareArr := StrSplit(axisComparison, ">")
            return (getAxisVal(compareArr[1]) < Float(compareArr[2]))
        }
    }
    else if (InStr(axisComparison, "=")) {
        compareArr := StrSplit(axisComparison, "=")
        return (getAxisVal(compareArr[1]) = Float(compareArr[2]))
    }

    return false
}