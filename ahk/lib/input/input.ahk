; abstract object that is used as the base for an individual input device
; stores the current state & required functions to check the state of the device
class Input {
    pluginID := ""
    pluginPort := -1
    name := ""

    vendorID  := 0
    productID := 0
    revisionID := 0

    connectedTime := -1
    connected := false
    vibrating := false

    ; connectionType
    ;  -1 -> unknown
    ;   0 -> wired
    ;   1 -> battery
    ;   2 -> bluetooth
    connectionType := -1

    ; valid range 0 -> 1
    batteryLevel := 0
    ; if true -> checks battery percentage in main rather than in inputThread
    batteryCheckBlocking := false

    ; map object to use for whatever ptrs are created in the initialization
    ; of the device type / individual device
    initResults := Map()

    ; state of input buttons/axis
    buttons := Map()
    axis    := Map()

    buttNames := []
    axisNames := []

    __New(initResults, pluginPort, inputConfigRef, restoreAttributes := "") {
        inputConfig := ObjDeepClone(inputConfigRef)
        this.buttons.CaseSense := "Off"
        this.buttons.Default := 0
        this.axis.CaseSense := "Off"
        this.axis.Default := 0

        ; restore controller details from backup
        if (restoreAttributes != "") {                
            for key, value in restoreAttributes {
                if (key = "initResults") {
                    continue
                }

                if (Type(value) = "Map") {
                    for key2, value2 in value {
                        this.%key%[key2] := value2
                    }
                }
                else {
                    this.%key% := value
                }
            }
        }
        
        this.pluginID := inputConfig["id"]
        this.pluginPort := pluginPort

        this.name :=      (inputConfig.Has("name"))    ? inputConfig["name"]    : this.name
        this.buttNames := (inputConfig.Has("buttons")) ? inputConfig["buttons"] : this.buttNames
        this.axisNames := (inputConfig.Has("axis"))    ? inputConfig["axis"]    : this.axisNames

        for item in this.buttNames {
            this.buttons[toString(item)] := false
        }
        for item in this.axisNames {
            this.axis[toString(item)] := 0
        }

        this.initResults := initResults
    }

    ; this should only run once to intialize the driver (beginning of script)
    static initialize() {

    }

    ; this should only run once to de-attach the driver (end of script)
    static destroy() {

    }
    
    ; this runs in main rather than in inputThread - relies on globalInputStatus
    ; should return map of pluginPorts to battery levels
    static checkBlockingBatteryLevels() {
        return Map()
    }

    ; this should only run once to intialize the controller port instance (after initialize)
    initDevice() { 
        
    } 

    ; this should only run once to remove the controller port instance (before destroy)
    destroyDevice() {

    }

    ; returns the state of the pressed buttons and each axis's current state
    getStatus() {
        return Map("buttons", this.buttons, "axis", this.axis)
    }

    ; returns & sets the product & vendor ids of the device
    checkDeviceInfo() {
        return Map(
            "name", this.name,
            "productID", this.productID,
            "vendorID", this.vendorID,
            "revisionID", this.revisionID
        )
    }

    ; returns & sets the connection type of the device
    checkConnectionType() {
        return this.connectionType
    }

    ; returns & sets the battery level of the device
    checkBatteryLevel() { 
        return this.batteryLevel
    }

    ; start vibrating the device if it supports vibrations
    startVibration() {

    }

    ; stop vibrating the device
    stopVibration() {

    }
}

; checks the button & axis status of an input device using the results from getStatus
;  key - single key to check
;  statusResults - the results from 1 input device's getStatus
;
; returns true if key matches
inputCheckStatus(key, statusResult) {
    cleanKey := Trim(key, " `t`r`n")
    if (InStr(cleanKey, ">")) {
        if (InStr(cleanKey, ">=")) {
            compareArr := StrSplit(cleanKey, ">=")
            if (compareArr.Length = 2) {
                return (statusResult["axis"][compareArr[1]] >= Float(compareArr[2]))
            }
        }
        else {
            compareArr := StrSplit(cleanKey, ">")
            if (compareArr.Length = 2) {
                return (statusResult["axis"][compareArr[1]] > Float(compareArr[2]))
            }
        }
    }
    else if (InStr(cleanKey, "<")) {
        if (InStr(cleanKey, "<=")) {
            compareArr := StrSplit(cleanKey, "<=")
            if (compareArr.Length = 2) {
                return (statusResult["axis"][compareArr[1]] <= Float(compareArr[2]))
            }
        }
        else {
            compareArr := StrSplit(cleanKey, "<")
            if (compareArr.Length = 2) {
                return (statusResult["axis"][compareArr[1]] < Float(compareArr[2]))
            }
        }
    }
    else if (InStr(cleanKey, "=")) {
        compareArr := StrSplit(cleanKey, "=")
        if (compareArr.Length = 2) {
            return (statusResult["axis"][compareArr[1]] = Float(compareArr[2]))
        }
    }

    return statusResult["buttons"][cleanKey]
}