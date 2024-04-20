class SteamProgram extends Program {
    __New(args*) {
        super.__New(args*)

        try {
            pathArr := StrSplit(RegRead("HKEY_CURRENT_USER\Software\Valve\Steam", "SteamExe"), "/")
            this.exe := pathArr.RemoveAt(pathArr.Length)
            this.dir := validateDir(joinArray(pathArr, "\"))       
        }
        catch {
            ErrorMsg("Steam not installed?")
        }
    }

    _launch(args*) {
        global globalStatus

        try {
            ; need to run steam as a regular user unless family sharing doesn't work????
            RunAsUser(this.dir . this.exe, args, this.dir)
        }
        catch {
            return false
        }
        
        resetTTM := A_TitleMatchMode
        SetTitleMatchMode(3)

        globalStatus["loadscreen"]["overrideWNDW"] := "Sign in to Steam"

        count := 0
        maxCount := 200

        ; wait for all steam executables to launch
        while (!(ProcessExist("steam.exe") && ProcessExist("steamservice.exe") && ProcessExist("steamwebhelper.exe")) && count < maxCount) {
            count += 1
            Sleep(100)
        }
        
        count := 0
        maxCount := 100

        firstShown := false
        ; idk how long to sleep for, steam doesn't really tell me when its done cooking
        while (count < maxCount) {
            if (!firstShown && WinShown(INTERFACES["loadscreen"]["wndw"]) && WinShown("Sign in to Steam")) {
                Sleep(500)

                ; need to flash alternate window in order to fix stupid steam black screen
                ; why is everything chromium?
                if (WinShown(INTERFACES["loadscreen"]["wndw"]) && WinShown("Sign in to Steam")) {
                    activateLoadScreen()
                    Sleep(80)
                    WinActivateForeground("Sign in to Steam")

                    firstShown := true
                }
            }
            
            MouseMove(percentWidth(1), percentHeight(1))
            count += 1
            Sleep(100)
        }

        globalStatus["loadscreen"]["overrideWNDW"] := ""
        SetTitleMatchMode(resetTTM)
    }

    _exit() {
        try {
            RunAsUser(this.dir . this.exe, "-shutdown", this.dir)

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