class FF8Program extends SteamGameProgramWithLauncher {
    _postLaunchDelay := 2000

    _launcherEXE := "FF8_Launcher.exe"
    _launcherMousePos := [[0.500, 0.950], [0.715, 0.540]]

    _postLaunch() {
        this.send("X")
        SetTimer(DelayPress.Bind(0), Neg(2000))

        return

        DelayPress(index) {
            if (!this.exists() || index > 2) {
                return
            }

            this.send("X")
            SetTimer(DelayPress.Bind(index + 1), Neg(2000))
        }
    }

    _postExit() {
        count := 0
        maxCount := 100

        while (!WinShown("ahk_exe " this._launcherEXE) && count < maxCount) {
            count += 1
            Sleep(100)
        }

        if (WinShown("ahk_exe " this._launcherEXE)) {
            WinClose("ahk_exe " this._launcherEXE)
            Sleep(500)
        }
    }
}

class FF9Program extends SteamGameProgramWithLauncher {
    _postLaunchDelay := 2000

    _launcherEXE := "FF9_Launcher.exe"
    _launcherMousePos := [0.850, 0.910]
}