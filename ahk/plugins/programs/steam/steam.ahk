class SteamProgram extends Program {
    _launch(args*) {
        global globalStatus

        enableWait := true
        ; check if custom "wait" arg exists
        loop args.Length {
            if (SubStr(StrLower(args[A_Index]), 1, 4) != "wait") {
                continue
            }

            tempArg := StrSplit(StrLower(args[A_Index]), "=",, 2)
            if (tempArg.Length > 1) {
                waitVal := Trim(tempArg[2])
                if (waitVal = "false" || waitVal = "0") {
                    enableWait := false
                }
            }

            args.RemoveAt(A_Index)
            break
        }

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
        ; wait for "Loggin In" window to appear
        while (!(ProcessExist("steamwebhelper.exe") && WinExist("Sign in to Steam")) && count < maxCount) {
            count += 1
            Sleep(100)
        }

        ; don't wait for the "Logging In" window to disappear
        if (!enableWait) {
            Sleep(2000)

            globalStatus["loadscreen"]["overrideWNDW"] := ""
            SetTitleMatchMode(resetTTM)
            return
        }

        count := 0
        maxCount := 200

        firstShown := false
        ; wait for "Loggin In" window to disappear
        while (WinExist("Sign in to Steam") && count < maxCount) {
            if (!firstShown && WinShown("Sign in to Steam")) {
                Sleep(1000)

                ; need to flash alternate window in order to fix stupid steam black screen
                ; why is everything chromium?
                if (WinShown(INTERFACES["loadscreen"]["wndw"]) && WinShown("Sign in to Steam")) {
                    activateLoadScreen()
                    Sleep(75)
                    WinActivateForeground("Sign in to Steam")

                    firstShown := true
                }
            }
            
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