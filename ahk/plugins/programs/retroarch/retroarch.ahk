class RetroArchEmulator extends Emulator {
    _launch(args*) {
        retArgs := []
        if (this.HasOwnProp("core") && this.core != "") {
            retArgs.Push("-L", "cores\" . this.core . "_libretro.dll")
        }
        
        if (args.Length > 0) {
            retArgs.Push(args*)
        }

        ; TODO - come up with way to start/stopdelfinovin in config
        if (StrLower(this.console) = "n64") {
            startDelfinovin()
        }

        super._launch(retArgs*)
    }
    
    _postExit() {
        stopDelfinovin()
    }

    _fullscreen() {
        this.send("{Alt down}")
        this.send("{Enter}")
        this.send("{Alt up}")
    }

    ; _pause() {
    ;     this.send("p", 150)
    ; }

    ; _resume() {
    ;     this._pause()
    ; }
    
    ; _saveState(slot) {
    ;     this.send("{F2}")
    ; }

    ; _loadState(slot) {
    ;     this.send("{F4}")
    ; }

    ; _reset() {
    ;     this.send("h")
    ; }

    ; _fastForward() {
    ;     this.send("{Space}")
    ; }

    ; _rewind() {
    ;     if (this.rewinding) {
    ;         this.send("{r up}")
    ;     }
    ;     else {
    ;         this.send("{r down}")
    ;     }
    ; }

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