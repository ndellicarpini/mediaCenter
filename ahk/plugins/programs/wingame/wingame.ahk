; launch a standard windows game from an executable path
;  game - full path of game executable
;  args - args to use when running game
;
; returns null
winGameLaunch(game, args*) {
    global globalRunning

    this := globalRunning["wingame"]

    pathArr := StrSplit(game, "\")
    
    exe := pathArr.RemoveAt(pathArr.Length)
    path := joinArray(pathArr, "\")

    if ((Type(args) = "String" && args != "") || (Type(args) = "Array" && args.Length > 0)) {
        Run game . " " . joinArray(args), path
    }
    else {
        Run game, path
    }

    ; custom actions based on game
    switch(game) {
        case "D:\Rockstar\Grand Theft Auto V\PlayGTAV.exe":
            this.launcher := Map("exe", "Launcher.exe", "mouseClick", [])
        case "D:\Games\Kingdom Hearts 1.5+2.5\KINGDOM HEARTS HD 1.5+2.5 ReMIX.exe"
            , "D:\Games\Kingdom Hearts 2.8\KINGDOM HEARTS HD 2.8 Final Chapter Prologue.exe"
            , "D:\Games\Kingdom Hearts III\KINGDOM HEARTS III\Binaries\Win64\KINGDOM HEARTS III.exe":
            this.hotkeys := Map("SELECT", Map("up", "Send '{Escape up}'", "down", "Send '{Escape down}'"))
        case "D:\Games\Simpsons Hit & Run\Lucas Simpsons Hit & Run Mod Launcher.exe":
            this.hotkeys := Map("START", Map("up", "Send '{Escape up}'", "down", "Send '{Escape down}'"))
        case "shell:AppsFolder\Microsoft.OpusPG_8wekyb3d8bbwe!OpusReleaseFinal":
            this.wndw := "Forza Horizon 3"
            this.allowPause := false
    }
}

; custom post launch action for windows game
winGamePostLaunch() {
    global globalRunning

    this := globalRunning["wingame"]

    ; custom action based on which executable is open
    switch(this.currEXE) {
        case "TestDriveUnlimited.exe": ; Test Drive Unlimited
            SetTimer(MouseMove.Bind(percentWidth(1, false), percentHeight(1, false)), -20000)
        case "openmw.exe": ; Morrowind
            SetTimer(MouseMove.Bind(percentWidth(0.5, false), percentHeight(0.5, false)), -2000)       
    }
}

; custom post executable close action for windows game
winGamePostExit() {
    global globalRunning
    
    this := globalRunning["wingame"]

    ; custom action based on which executable is open
    switch (this.currEXE) {
        case "GTA5.exe": ; GTA 5
            count := 0
            maxCount := 100

            while (!WinShown("Rockstar Games Launcher") && count < maxCount) {
                count += 1
                Sleep(100)
            }

            if (WinShown("Rockstar Games Launcher")) {
                WinClose("Rockstar Games Launcher")
                Sleep(500)
            }
    }
}