; run an amazon game from amazon URI
;  URI - link to launch game
;  args - args to use when running game
;
; returns null
amazonGameLaunch(URI, args*) {
    global globalConfig
    global globalRunning

    this := globalRunning["amazongame"]

    Run URI

    count := 0
    maxCount := 40

    setLoadScreen("Waiting for Amazon Games...")
    
    resetTMM := A_TitleMatchMode
    SetTitleMatchMode 2

    restoreAllowExit := this.allowExit
    this.allowExit := true

    globalStatus["loadscreen"]["overrideWNDW"] := "Amazon Games"

    ; wait for amazon to show
    while (!this.exists(true) && count < maxCount) {
        if (WinShown("Amazon Games")) {            
            count := 0
        }

        if (this.shouldExit) {
            globalStatus["loadscreen"]["overrideWNDW"] := ""

            amazonGamePostExit()
            SetTitleMatchMode(resetTMM)

            return -1
        }

        count += 1
        Sleep(500)
    }

    this.allowExit := restoreAllowExit
    globalStatus["loadscreen"]["overrideWNDW"] := ""
}

; close amazon game launcher after game exits
amazonGamePostExit() {
    count := 0
    maxCount := 100
    ; wait for amazon game launcher to show
    while (!WinShown("Amazon Games") && count < maxCount) {
        count += 1
        Sleep(100)
    }

    count := 0
    maxCount := 20
    ; try to close amazon game launcher while open
    while (WinShown("Amazon Games") && count < maxCount) {
        WinActivate("Amazon Games")
        Sleep(100)
        WinClose("Amazon Games")

        count += 1
        Sleep(500)
    }

    if (ProcessExist("Amazon Games.exe") && count >= maxCount) {
        ProcessClose("Amazon Games.exe")
    }
}