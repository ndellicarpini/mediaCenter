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

class SteamNewUIProgram extends Program {
    _launch(args*) {
        global globalStatus

        resetTTM := A_TitleMatchMode
        SetTitleMatchMode(3)

        globalStatus["loadscreen"]["overrideWNDW"] := "Sign in to Steam"

        ; need to run steam as a regular user unless family sharing doesn't work????
        RunAsUser(this.dir . this.exe, args, this.dir)
        
        count := 0
        maxCount := 200
        ; wait for "Loggin In" window to appear
        while (!(ProcessExist("steamwebhelper.exe") && WinExist("Sign in to Steam")) && count < maxCount) {
            count += 1
            Sleep(100)
        }

        count := 0
        maxCount := 200
        ; wait for "Loggin In" window to disappear
        while (WinExist("Sign in to Steam") && count < maxCount) {
            count += 1
            Sleep(100)
        }

        globalStatus["loadscreen"]["overrideWNDW"] := ""
        SetTitleMatchMode(resetTTM)
    }

    _exit() {
        RunAsUser(this.dir . this.exe, "-shutdown", this.dir)

        try {
            count := 0
            maxCount := 400
            ; wait for program executable to close
            while (this.exists() && count < maxCount) {
                exe := this.getEXE()
                if (exe = "") {
                    break
                }

                ; attempt to processclose @ 30s
                if (count = 300) {
                    ProcessClose(exe)
                }
                
                count += 1
                Sleep(100)
            }

            Sleep(1000)

            ; if exists -> go nuclear @ 40s
            if (this.exists()) {
                ProcessKill(this.getPID())
            }
        }
    }
}