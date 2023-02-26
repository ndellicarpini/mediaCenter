class SteamProgram extends Program {
    _launch(args*) {
        super._launch(args*)
        Sleep(5000)
    }

    _exit() {
        Run(this.dir . this.exe . " -shutdown", this.dir)

        try {
            count := 0
            maxCount := 250
            ; wait for program executable to close
            while (this.exists() && count < maxCount) {
                exe := this.getEXE()
                if (exe = "") {
                    break
                }

                ; attempt to processclose @ 20s
                if (count = 200) {
                    ProcessClose(exe)
                }
                
                count += 1
                Sleep(100)
            }

            Sleep(1000)

            ; if exists -> go nuclear @ 25s
            if (this.exists()) {
                ProcessKill(this.getPID())
            }
        }
    }
}