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
    buttons := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    axis    := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    buttNames := []
    axisNames := []

    __New(initResults, pluginPort, inputConfigRef, restoreAttributes := "") {
        inputConfig := ObjDeepClone(inputConfigRef)

        ; restore controller details from backup
        if (restoreAttributes != "") {                
            for key, value in restoreAttributes {
                this.%key% := value
            }
        }
        
        this.pluginID := inputConfig["id"]
        this.pluginPort := pluginPort

        this.name :=      (inputConfig.Has("name"))    ? inputConfig["name"]    : this.name
        this.buttNames := (inputConfig.Has("buttons")) ? inputConfig["buttons"] : this.buttNames
        this.axisNames := (inputConfig.Has("axis"))    ? inputConfig["axis"]    : this.axisNames

        this.initResults := initResults
        
        this.initDevice()
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
        this.buttons := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        this.axis    := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        
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
    if (IsInteger(cleanKey)) {
        return statusResult["buttons"][Integer(cleanKey)]
    }
    else {
        return inputCompareAxis(cleanKey, statusResult)
    }
}

; checks if a hotkey is an axis comparison, then checks if the input status satisfies the comparison
;  axisComparison - hotkey that will be compared if its in the appropriate format
;  statusResults - the results from 1 input device's getStatus
;
; returns true if the axis comparison is satisfied
inputCompareAxis(axisComparison, statusResult) {
    if (InStr(axisComparison, ">")) {
        if (InStr(axisComparison, ">=")) {
            compareArr := StrSplit(axisComparison, ">=")
            return (statusResult["axis"][Integer(compareArr[1])] >= Float(compareArr[2]))
        }
        else {
            compareArr := StrSplit(axisComparison, ">")
            return (statusResult["axis"][Integer(compareArr[1])] > Float(compareArr[2]))
        }
    }
    else if (InStr(axisComparison, "<")) {
        if (InStr(axisComparison, "<=")) {
            compareArr := StrSplit(axisComparison, "<=")
            return (statusResult["axis"][Integer(compareArr[1])] <= Float(compareArr[2]))
        }
        else {
            compareArr := StrSplit(axisComparison, "<")
            return (statusResult["axis"][Integer(compareArr[1])] < Float(compareArr[2]))
        }
    }
    else if (InStr(axisComparison, "=")) {
        compareArr := StrSplit(axisComparison, "=")
        return (statusResult["axis"][Integer(compareArr[1])] = Float(compareArr[2]))
    }

    return false
}