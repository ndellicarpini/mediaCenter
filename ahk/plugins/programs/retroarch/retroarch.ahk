class RetroArchEmulator extends Emulator {
    __New(args*) {
        super.__New(args*)

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
    }

    _launch(args*) {
        ; cheater cheater pumpkin eater
        for arg in args {
            if (Type(arg) = "String" && InStr(StrLower(arg), "neo turf masters")) {
                this.core := "neocd"
                break
            }
        }

        retArgs := []
        if (this.HasOwnProp("core") && this.core != "") {
            retArgs.Push("-L", "cores\" . this.core . "_libretro.dll")
        }
        
        if (args.Length > 0) {
            retArgs.Push(args*)
        }

        super._launch(retArgs*)
    }

    _fullscreen() {
        this.send("{Alt down}")
        this.send("{Enter}")
        this.send("{Alt up}")
    }

    _pause() {
        this.send("p", 150)
    }

    _resume() {
        this._pause()
    }
    
    _saveState(slot) {
        this.send("{F2}")
    }

    _loadState(slot) {
        this.send("{F4}")
    }

    _reset() {
        this.send("h")
    }

    _fastForward() {
        this.send("{Space}")
    }

    _rewind() {
        if (this.rewinding) {
            this.send("{r up}")
        }
        else {
            this.send("{r down}")
        }
    }

    ; custom function
    menu() {
        Sleep(50)
        this.send("{F1}")
    }

    ; custom function
    mameMenu() { 
        Sleep(50)       
        this.send("{Tab}")
    }
}