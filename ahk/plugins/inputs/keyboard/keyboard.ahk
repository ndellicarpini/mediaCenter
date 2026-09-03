class AHIWrapper extends AutoHotInterception {
    __New() {
        ; modified to work in thread

		bitness := A_PtrSize == 8 ? "x64" : "x86"
		dllName := "interception.dll"

		dllFile := A_LineFile "\..\lib\AutoHotInterception\Lib\" bitness "\" dllName
		if (!FileExist(dllFile)) {
			MsgBox("Unable to find " dllFile ", exiting...`nYou should extract both x86 and x64 folders from the library folder in interception.zip into AHI's lib folder.")
			ExitApp
		}

		hModule := DllCall("LoadLibrary", "Str", dllFile, "Ptr")
		if (hModule == 0) {
			this_bitness := A_PtrSize == 8 ? "64-bit" : "32-bit"
			other_bitness := A_PtrSize == 4 ? "64-bit" : "32-bit"
			MsgBox("Bitness of " dllName " does not match bitness of AHK.`nAHK is " this_bitness ", but " dllName " is " other_bitness ".")
			ExitApp
		}
		DllCall("FreeLibrary", "Ptr", hModule)

		dllName := "AutoHotInterception.dll"
        dllFile := A_LineFile "\..\lib\AutoHotInterception\Lib\" dllName
		hintMessage := "Try right-clicking " dllFile ", select Properties, and if there is an 'Unblock' checkbox, tick it`nAlternatively, running Unblocker.ps1 in the lib folder (ideally as admin) can do this for you."
		if (!FileExist(dllFile)) {
			MsgBox("Unable to find " dllFile ", exiting...")
			ExitApp
		}

		asm := CLR_LoadLibrary(dllFile)
		try {
			this.Instance := asm.CreateInstance("AutoHotInterception.Manager")
		}
		catch {
			MsgBox(dllName " failed to load`n`n" hintMessage)
			ExitApp
		}
		if (this.Instance.OkCheck() != "OK") {
			MsgBox(dllName " loaded but check failed!`n`n" hintMessage)
			ExitApp
		}
    }
}


class KeyboardDevice extends Input {
    blockKeyboard := false
    blockMouse := false

    _keyboardID  := 0
    keyboardVID := 0
    keyboardPID := 0
    _mouseID  := 0
    mouseVID := 0
    mousePID := 0

    mouseButtonArr := ["lclick", "rclick", "mclick", "button1", "button2", 
                       "wheelup", "wheeldown", "wheelleft", "wheelright"]

    _currVSource  := ""
    _currVInput   := []
    _currVHotkeys := Map()

    _vButtons := Map()
    _axisTime := 0 

    _internalButtons := Map()
    _forceFirstInput := ""

    __New(initResults, pluginPort, inputConfigRef, restoreAttributes := "") {
        this._currVHotkeys.CaseSense := "Off"
        this._currVHotkeys.Default := 0 
        this._vButtons.CaseSense := "Off"
        this._vButtons.Default := 0 

        super.__New(initResults, pluginPort, inputConfigRef, restoreAttributes)
        inputConfig := ObjDeepClone(inputConfigRef)
        
        this.maxConnected := 1
        this.keyboardVID := (inputConfig.Has("keyboardVID")) ? Integer(inputConfig["keyboardVID"]) : this.keyboardVID
        this.keyboardPID := (inputConfig.Has("keyboardPID")) ? Integer(inputConfig["keyboardPID"]) : this.keyboardPID
        this.mouseVID    := (inputConfig.Has("mouseVID"))    ? Integer(inputConfig["mouseVID"])    : this.mouseVID
        this.mousePID    := (inputConfig.Has("mousePID"))    ? Integer(inputConfig["mousePID"])    : this.mousePID

        this.vendorID  := (this.keyboardVID != 0) ? this.keyboardVID : this.mouseVID
        this.productID := (this.keyboardPID != 0) ? this.keyboardPID : this.mousePID
    }

    static initialize() {
        scpLib := CLR_LoadLibrary("plugins\inputs\keyboard\lib\SCPDriverInterface\ScpDriverInterface.dll")
        scpBus := SCPLib.CreateInstance("ScpDriverInterface.ScpBus")
        ahi := AHIWrapper()

        return Map(
            "scpLib", scpLib,
            "scpBus", scpBus,
            "ahi", ahi
        )
    }

    initDevice() {
        this._vButtons["DU"] := 1 << 0
        this._vButtons["DD"] := 1 << 1
        this._vButtons["DL"] := 1 << 2
        this._vButtons["DR"] := 1 << 3
        this._vButtons["START"] := 1 << 4
        this._vButtons["SELECT"] := 1 << 5
        this._vButtons["LSB"] := 1 << 6
        this._vButtons["RSB"] := 1 << 7
        this._vButtons["LB"] := 1 << 8
        this._vButtons["RB"] := 1 << 9
        this._vButtons["HOME"] := 1 << 10
        this._vButtons["A"] := 1 << 12
        this._vButtons["B"] := 1 << 13
        this._vButtons["X"] := 1 << 14
        this._vButtons["Y"] := 1 << 15

        this.connected := true
        this.connectedTime := GetLocaleUnixTimestep()

        this._enableKeyboard()
        this._enableMouse()
    }

    destroyDevice() {
        this.buttons := Map()
        this.axis := Map()

        this._currVSource := ""
        this._forceFirstInput := ""
        this._internalButtons := Map()

        this._disableKeyboard()
        this._disableMouse()

        while (this._currVInput.Length > 0) {
            this.initResults["scpBus"].Unplug(this._currVInput.Length)
            this._currVInput.Pop()
        }
    }

    getStatus() {
        global globalStatus                                     

        try {
            currSource := ""
            if (globalStatus["input"]["hotkeys"].Has("keyboard")) {
                for key, _ in globalStatus["input"]["hotkeys"]["keyboard"] {
                    currSource .= key
                }
                
                if (globalStatus["input"]["hotkeys"]["keyboard"].Has("blockKeyboard")) {
                    currSource .= globalStatus["input"]["hotkeys"]["keyboard"]["blockKeyboard"]
                }
                if (globalStatus["input"]["hotkeys"]["keyboard"].Has("blockMouse")) {
                    currSource .= globalStatus["input"]["hotkeys"]["keyboard"]["blockMouse"]
                }
            }
            if (globalStatus["input"]["mouse"].Has("keyboard")) {
                for _, val in globalStatus["input"]["mouse"]["keyboard"] {
                    currSource .= val
                }
            }
            
            if (currSource != this._currVSource) {
                this._currVSource := currSource

                currBlockKeyboard := false
                currBlockMouse    := false
                if (!globalStatus["suspendScript"]) {
                    currBlockKeyboard := this.blockKeyboard
                    if (globalStatus["input"]["hotkeys"].Has("keyboard") && globalStatus["input"]["hotkeys"]["keyboard"].Has("blockKeyboard")) {
                        currBlockKeyboard := globalStatus["input"]["hotkeys"]["keyboard"]["blockKeyboard"]
                    }

                    currBlockMouse := this.blockMouse
                    if (globalStatus["input"]["hotkeys"].Has("keyboard") && globalStatus["input"]["hotkeys"]["keyboard"].Has("blockMouse")) {
                        currBlockMouse := globalStatus["input"]["hotkeys"]["keyboard"]["blockMouse"]
                    }
                }

                if (currBlockKeyboard != this.blockKeyboard) {
                    this.blockKeyboard := currBlockKeyboard

                    this._disableKeyboard()
                    Sleep(100)
                    
                    ; reset state of buttons on swapperoni
                    ; otherwise a button could be released between disable & enable
                    this._forceFirstInput := ""
                    this._internalButtons := Map()
                    for key, _ in this.buttons {
                        this.buttons[key] := false
                    }

                    this._enableKeyboard()
                }
                if (currBlockMouse != this.blockMouse) {
                    this.blockMouse := currBlockMouse 

                    this._disableMouse()
                    Sleep(100)
                    
                    ; reset state of buttons on swapperoni
                    ; otherwise a button could be released between disable & enable
                    this._forceFirstInput := ""
                    this._internalButtons := Map()
                    for key, _ in this.buttons {
                        this.buttons[key] := false
                    }
                    
                    this._enableMouse()
                }

                ; dont change controller settings when a GUI is open
                if (globalStatus["currGui"] = "") {
                    maxControllers := 0
                    hasVKeyboard := globalStatus["input"]["hotkeys"].Has("keyboard") && globalStatus["input"]["hotkeys"]["keyboard"].Has("vinput")
                    if (hasVKeyboard) {
                        maxControllers := Max(maxControllers, globalStatus["input"]["hotkeys"]["keyboard"]["vinput"].Length)
                    }

                    hasVMouse:= globalStatus["input"]["mouse"].Has("keyboard") && globalStatus["input"]["mouse"]["keyboard"].Has("vinput")
                    if (hasVMouse) {
                        maxControllers := Max(maxControllers, globalStatus["input"]["mouse"]["keyboard"]["vinput"].Length)
                    }

                    numVInput := this._currVInput.Length
                    loop Max(maxControllers, numVInput) {
                        this._currVHotkeys := Map()
                        if (hasVKeyboard) {
                            loop globalStatus["input"]["hotkeys"]["keyboard"]["vinput"].Length {
                                port := A_Index
                                for key, value in globalStatus["input"]["hotkeys"]["keyboard"]["vinput"][A_Index] {
                                    this._currVHotkeys[GetKeySC(key)] := [port, value]
                                }
                            }
                        }
                        if (hasVMouse) {
                            loop globalStatus["input"]["mouse"]["keyboard"]["vinput"].Length {
                                port := A_Index
                                for key, value in globalStatus["input"]["hotkeys"]["mouse"]["vinput"][A_Index] {
                                    this._currVHotkeys[key] := [port, value]
                                }
                            }
                        }

                        if (A_Index > numVInput) {
                            this.initResults["scpBus"].PlugIn(A_Index)
                            this._currVInput.Push(this.initResults["scpLib"].CreateInstance("ScpDriverInterface.X360Controller"))
                        }
                        else if (A_Index > maxControllers) {
                            this.initResults["scpBus"].Unplug(this._currVInput.Length)
                            this._currVInput.Pop()
                        }
                    }
                }
            }
        }

        for key, buffer in this._internalButtons {
            if (buffer.Length > 0) {
                this.buttons[key] := buffer.RemoveAt(1)
            }
        }

        if ((this.axis["MOUSEX"] != 0 || this.axis["MOUSEY"] != 0) && A_TickCount > (this._axisTime + 20)) {
            this.axis["MOUSEX"] := 0
            this.axis["MOUSEY"] := 0
        }
        
        return Map("buttons", this.buttons, "axis", this.axis)
    }

    _enableKeyboard() {
        if (this._keyboardID != 0 || this.keyboardVID = 0 || this.keyboardPID = 0) {
            return
        }

        this._keyboardID := this.initResults["ahi"].GetKeyboardId(this.keyboardVID, this.keyboardPID)
        this.initResults["ahi"].SubscribeKeyboard(this._keyboardID, this.blockKeyboard, OnKeyboard, true)

        return

        OnKeyboard(code, state) {
            if (this._currVInput.Length > 0 && this._currVHotkeys.Has(code)) {
                this._handleVInput(this._currVHotkeys[code][1], this._currVHotkeys[code][2], state)
            }

            keyName := String(GetKeyName(Format("sc{:X}", code)))
            if (!this._internalButtons.Has(keyName)) {
                if (this._forceFirstInput = "") {
                    this._forceFirstInput := keyName
                    state := 1
                }
                this._internalButtons[keyName] := [state]
            }
            else {      
                if (this._forceFirstInput = keyName) {
                    this._forceFirstInput := "-1"
                    state := 0
                }           
                if (this._internalButtons[keyName].Length = 0 || this._internalButtons[keyName][this._internalButtons[keyName].Length] != state) {
                    this._internalButtons[keyName].Push(state)
                }
            }
            return
        }
    }

    _disableKeyboard() {
        if (this._keyboardID = 0) {
            return
        }
        
        this.initResults["ahi"].UnsubscribeKeyboard(this._keyboardID)
        this._keyboardID := 0
    }

    _enableMouse() {
        if (this._mouseID != 0 || this.mouseVID = 0 || this.mousePID = 0) {
            return
        }

        this._mouseID := this.initResults["ahi"].GetMouseId(this.mouseVID, this.mousePID)
        this.initResults["ahi"].SubscribeMouseButtons(this._mouseID, this.blockMouse, OnMouseButton, true)
        this.initResults["ahi"].SubscribeMouseMoveRelative(this._mouseID, this.blockMouse, OnMouseMove, false)

        return

        OnMouseButton(code, state) {
            if (this._currVInput.Length > 0 && this._currVHotkeys.Has(code)) {
                this._handleVInput(this._currVHotkeys[code][1], this._currVHotkeys[code][2], state)
            }
            
            if (code < 5) {
                keyName := this.mouseButtonArr[code + 1]
                if (!this._internalButtons.Has(keyName)) {
                    if (this._forceFirstInput = "") {
                        this._forceFirstInput := keyName
                        state := 1
                    }
                    this._internalButtons[keyName] := [state]
                }
                else {
                    if (this._forceFirstInput = keyName) {
                        this._forceFirstInput := "-1"
                        state := 0
                    }
                    if (this._internalButtons[keyName].Length = 0 || this._internalButtons[keyName][this._internalButtons[keyName].Length] != state) {
                        this._internalButtons[keyName].Push(state)
                    }
                }
            }
            else if (code = 5) {
                if (!this._internalButtons.Has("wheelup")) {
                    this._internalButtons["wheelup"] := [(state = 1)]
                    this._internalButtons["wheeldown"] := [(state = -1)]
                }
                else if (this._internalButtons["wheelup"].Length = 0 || this._internalButtons["wheelup"][this._internalButtons["wheelup"].Length] != (state = 1)) {
                    this._internalButtons["wheelup"].Push(state = 1)
                    this._internalButtons["wheeldown"].Push(state = -1)
                }
            }
            else if (code = 6) {
                if (!this._internalButtons.Has("wheelright")) {
                    this._internalButtons["wheelright"] := [(state = 1)]
                    this._internalButtons["wheelleft"] := [(state = -1)]
                }
                else if (this._internalButtons["wheelright"].Length = 0 || this._internalButtons["wheelright"][this._internalButtons["wheelright"].Length] != (state = 1)) {
                    this._internalButtons["wheelright"].Push(state = 1)
                    this._internalButtons["wheelleft"].Push(state = -1)
                }
            }
            return
        }
        OnMouseMove(x, y) { 
            this._axisTime := A_TickCount
            this.axis["MOUSEX"] := Abs(x) > 1 ? (x < 0 ? -1 : 1) : 0
            this.axis["MOUSEY"] := Abs(y) > 1 ? (y < 0 ? -1 : 1) : 0
            return
        }
    }

    _disableMouse() {
        if (this._mouseID = 0) {
            return
        }

        this.initResults["ahi"].UnsubscribeMouseButtons(this._mouseID)
        this.initResults["ahi"].UnsubscribeMouseMoveRelative(this._mouseID)
        this._mouseID := 0
    }

    _handleVInput(port, button, state) {
        if (this._currVInput.Length < port) {
            return
        }

        if (state) {
            switch button, "Off" {
                case "LT":
                    this._currVInput[port].LeftTrigger := 255
                case "RT":
                    this._currVInput[port].RightTrigger := 255
                case "LSU":
                    this._currVInput[port].LeftStickY := 32767
                case "LSD":
                    this._currVInput[port].LeftStickY := -32767
                case "LSL":
                    this._currVInput[port].LeftStickX := -32767
                case "LSR":
                    this._currVInput[port].LeftStickX := 32767
                case "RSU":
                    this._currVInput[port].RightStickY := 32767
                case "RSD":
                    this._currVInput[port].RightStickY := -32767
                case "RSL":
                    this._currVInput[port].RightStickX := -32767
                case "RSR":
                    this._currVInput[port].RightStickX := 32767
                default:
                    this._currVInput[port].Buttons |= this._vButtons[button]
            }
        }
        else {
            switch button, "Off" {
                case "LT":
                    this._currVInput[port].LeftTrigger := 0
                case "RT":
                    this._currVInput[port].RightTrigger := 0
                case "LSU", "LSD":
                    this._currVInput[port].LeftStickY := 0
                case "LSL", "LSR":
                    this._currVInput[port].LeftStickX := 0
                case "RSU", "RSD":
                    this._currVInput[port].RightStickY := 0
                case "RSL", "RSR":
                    this._currVInput[port].RightStickX := 0
                default:
                    this._currVInput[port].Buttons &= ~this._vButtons[button]
            }
            
        }

        this.initResults["scpBus"].Report(port, this._currVInput[port].GetReport())
    }
}