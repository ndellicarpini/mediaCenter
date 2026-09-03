class MameEmulator extends Emulator {
    _launch(args*) {
        if (super._launch(args*) = false) {
            return false
        }

        maxCount := 50

        restoreTMM := A_TitleMatchMode
        SetTitleMatchMode(3)

        try {
            ; need to hide MAME cmd since sometimes it will appear on side of game window

            count := 0
            while (!WinShown(this.dir . this.exe)) {
                count += 1
                Sleep(200)
            }

            count := 0
            while (count < maxCount && WinGetMinMax(cmdWndw) != -1) {
                cmdWndw := WinShown(this.dir . this.exe)
                if (cmdWndw) {
                    WinMinimize(cmdWndw)
                }

                count += 1
                Sleep(200)
            }
        }

        SetTitleMatchMode(restoreTMM)
        activateLoadScreen()
    }

    ; custom function
    menu() {
        Sleep(50)
        this.send("{Shift down}")
        Sleep(80)
        this.send("0")
        Sleep(80)
        this.send("{Shift up}")
    }
}