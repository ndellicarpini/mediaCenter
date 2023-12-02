class SM64Program extends WinGameProgram {
    _launch(game, args*) {
        gcnAdapterPath := "C:\GCN XInput Adapter"

        if (DirExist(gcnAdapterPath)) {
            try {
                RunAsUser(gcnAdapterPath .  "\Delfinovin.exe", "", gcnAdapterPath)
            }
            catch {
                return false
            }

            count := 0
            maxCount := 100
            while (!WinShown("Delfinovin") && count < maxCount) {
                Sleep(100)
                count += 1
            }
    
            if (count < maxCount) {
                Sleep(2000)
            }
            else {
                return false
            }
        }

        super._launch(game, args*)
    }

    _getEXE() {
        if (ProcessExist("sm64.us.exe")) {
            return "sm64.us.exe"
        }
        if (ProcessExist("Super Mario 64 Plus.exe")) {
            return "Super Mario 64 Plus.exe"
        }

        return ""
    }

    _postExit() {
        count := 0
        maxCount := 5
        while (ProcessExist("Delfinovin.exe") && count < maxCount) {
            WinClose("ahk_exe Delfinovin.exe")

            Sleep(3000)
            count += 1
        }
    }
}

class HarkinianProgram extends WinGameProgram {
    _launch(game, args*) {
        gcnAdapterPath := "C:\GCN XInput Adapter"

        if (DirExist(gcnAdapterPath)) {
            try {
                RunAsUser(gcnAdapterPath .  "\Delfinovin.exe", "", gcnAdapterPath)
            }
            catch {
                return false
            }

            count := 0
            maxCount := 100
            while (!WinShown("Delfinovin") && count < maxCount) {
                Sleep(100)
                count += 1
            }
    
            if (count < maxCount) {
                Sleep(2000)
            }
            else {
                return false
            }
        }

        super._launch(game, args*)
    }

    _postExit() {
        count := 0
        maxCount := 5
        while (ProcessExist("Delfinovin.exe") && count < maxCount) {
            WinClose("ahk_exe Delfinovin.exe")

            Sleep(3000)
            count += 1
        }
    }

    _fullscreen() {
        this.send("{F11}")
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
