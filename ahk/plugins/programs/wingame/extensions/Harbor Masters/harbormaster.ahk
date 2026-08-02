class HarborMasterProgram extends WinGameProgram {
    _launch(game, args*) {
        startDelfinovin()
        super._launch(game, args*)

        if (!InStr(StrLower(game), "soh.exe")) {
            toDelete := []
            loop this.pauseOrder.Length {
                item := this.pauseOrder[A_Index]

                if (this.pauseOptions.Has(item) && (
                        this.pauseOptions[item] = "program.reset" 
                        || this.pauseOptions[item] = "program.loadState" 
                        || this.pauseOptions[item] = "program.saveState"
                    )) {
                    
                    toDelete.Push(A_Index)
                }
            }

            if (toDelete.Length > 1) {
                loop toDelete.Length {
                    this.pauseOrder.RemoveAt(toDelete[A_Index] - (A_Index - 1))
                }
            }
        }
    }

    _postExit() {
        stopDelfinovin()
    }

    _fullscreen() {
        this.send("{F11}")
    }

    menu() {
        this.send("{Esc}")
    }

    saveState() {
        this.send("{F5}")
    }

    loadState() {
        this.send("{F7}")
    }

    reset() {
        this.send("{Ctrl down}")
        this.send("r")
        this.send("{Ctrl up}")
    }
}
