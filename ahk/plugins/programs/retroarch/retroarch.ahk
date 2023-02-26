class RetroArchEmulator extends Emulator {
    _launch(args*) {
        retArgs := []
        if (this.HasOwnProp("core") && this.core != "") {
            ; remove mame menu from pause options if not mame
            if (this.core != "mame") {
                loop this.pauseOrder.Length {
                    item := this.pauseOrder[A_Index]

                    if (this.pauseOptions.Has(item) && this.pauseOptions[item] = "program.mameMenu") {
                        this.pauseOrder.RemoveAt(A_Index)
                        break
                    }
                }
            }

            retArgs.Push("-L", "cores\" . this.core . "_libretro.dll")
        }
        
        if (args.Length > 0) {
            retArgs.Push(args*)
        }

        super._launch(retArgs*)
    }

    _fullscreen() {
        Send("{Alt down}")
        SendSafe("{Enter}")
        Send("{Alt up}")
    }

    _pause() {
        SendSafe("p")
    }

    _resume() {
        this._pause()
    }
    
    _saveState(slot) {
        SendSafe("{F2}")
    }

    _loadState(slot) {
        SendSafe("{F4}")
    }

    _reset() {
        SendSafe("h")
    }

    _fastForward() {
        SendSafe("{Space}")
    }

    _rewind() {
        if (this.rewinding) {
            Send("{r up}")
        }
        else {
            Send("{r down}")
        }
    }

    ; custom function
    menu() {
        Sleep(50)
        SendSafe("{F1}")
    }

    ; custom function
    mameMenu() { 
        Sleep(50)       
        SendSafe("{Tab}")
    }
}