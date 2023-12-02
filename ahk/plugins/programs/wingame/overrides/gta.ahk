class GTA5Program extends WinGameProgramWithLauncher {
    _launcherEXE := "Launcher.exe"

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