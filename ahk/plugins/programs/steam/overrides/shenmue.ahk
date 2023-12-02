class ShenmueProgram extends SteamGameProgramWithLauncher {
    _postLaunchDelay := 500
    _launcherEXE := "SteamLauncher.exe"

    _launch(URI, args*) {
        version := Integer(args.RemoveAt(1))
        if (version = 1) {
            this._launcherMousePos := [0.250, 0.500]
        }
        else if (version = 2) {
            this._launcherMousePos := [0.750, 0.500]
        }

        super._launch(URI, args*)
    }

    _postLaunch() {
        this.send("{Enter}")
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