; --- DEFAULT STEAM APP ---
class SteamGameProgram extends Program {
    _launch(URI, args*) {
        global globalStatus
        global globalRunning

        ; checks for common steam windows
        steamShown() {
            return WinShown("Install - ") || WinShown("Updating ") || WinShown("Ready - ") 
                || WinShown(" - Steam") || WinShown("Steam Dialog")
        }
    
        ; checks if the eula is open & accepts it
        checkDialogs() {
            if (WinShown(" Dialog")) {
                WinClose(" Dialog")
            }
    
            if (WinShown("Install - ")) {
                WinActivate("Install - ")
                Sleep(100)
                Send "{Enter}"
            }
        }

        ; skips all steam dialogs and launches the game
        launchHandler(game, loopCount := 0) {
            restoreAllowExit := this.allowExit
        
            restoreLoadText := globalStatus["loadscreen"]["text"]
            setLoadScreen("Waiting for Steam...")
            loadText := globalStatus["loadscreen"]["text"]
        
            restoreTTMM := A_TitleMatchMode
            SetTitleMatchMode(2)
        
            ; launch steam if it doesn't exist
            if (!globalRunning.Has("steam") || !globalRunning["steam"].exists()) {
                if (!globalRunning.Has("steam")) {
                    createProgram("steam", true, false)
                }
                else if (!globalRunning["steam"].exists()) {
                    globalRunning["steam"].launch()
                }
            
                ; TODO - fix getting cucked by the reset timeout
                setLoadScreen("Waiting for Steam...")
        
                this.allowExit := true
                
                count := 0
                maxCount := 100
                ; buffer wait for steam so that the URI works
                while (count < maxCount) {
                    if (this.shouldExit) {    
                        SetTitleMatchMode(restoreTTMM)
                        return false
                    }
        
                    count += 1
                    Sleep(100)
                }
        
                this.allowExit := false
            }
        
            Run(RTrim(game . A_Space . joinArray(args), A_Space))
        
            count := 0
            maxCount := 40
            ; wait for either the game or a common steam window
            while (count < maxCount && !steamShown() && !this.exists()) {
                if (count > 25 && this.shouldExit) {    
                    SetTitleMatchMode(restoreTTMM)
                    return false
                }
        
                count += 1
                Sleep(500)
            }
        
            ; if game -> success
            if (this.exists()) {
                this.allowExit := restoreAllowExit
                SetTitleMatchMode(restoreTTMM)
        
                return
            }
        
            ; if no steam windows shown -> restart steam
            if (!steamShown()) {
                if (loopCount > 2) {
                    SetTitleMatchMode(restoreTTMM)
                    return false
                }
        
                globalRunning["steam"].exit()
                
                Sleep(2000)
                return launchHandler(game, loopCount + 1)
            }
        
            this.allowExit := true
            
            setLoadScreen(restoreLoadText)
            globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe " globalRunning["steam"].getEXE()
        
            ; while launching window is shown, just wait
            while (WinShown(" - Steam")) {
                checkDialogs()
                Sleep(250)
            }
        
            updateWidth := Floor(percentWidth(0.4, false))
        
            ; while game updating -> resize update windows for funsies
            while (WinShown("Updating ")) {
                try {            
                    WinGetPos(&X, &Y, &W, &H, "Updating ")
                    if (W != updateWidth) {
                        WinMove((Floor(percentWidth(0.5, false)) - Floor(updateWidth / 2)), Y, updateWidth, H)
                    }
                }
        
                if (this.shouldExit) {   
                    globalStatus["loadscreen"]["overrideWNDW"] := ""
        
                    WinClose("Updating ")
                    SetTitleMatchMode(restoreTTMM)
        
                    return false
                }
        
                checkDialogs()
        
                Sleep(500)
            }
        
            checkDialogs()
        
            ; if game finishes updating -> click play button
            while (WinShown("Ready - ")) {  
                try {
                    WinGetPos(&X, &Y, &W, &H, "Ready - ")
                    ; the perfect infinite subpixel
                    mouseX := Floor(percentWidthRelativeWndw(0.915, "Ready - "))
                    mouseY := Floor(percentHeightRelativeWndw(0.658, "Ready - "))
            
                    Sleep(75)
                    MouseMove(mouseX, mouseY)
                    Sleep(75)
                    MouseClick("Left")
                    Sleep(75)
                    MouseMove(percentWidth(1, false), percentHeight(1, false))
                }
        
                if (this.shouldExit) {   
                    globalStatus["loadscreen"]["overrideWNDW"] := ""
        
                    WinClose("Ready - ")
                    SetTitleMatchMode(restoreTTMM)
        
                    return false
                }
        
                checkDialogs()
        
                Sleep(2000)
            }   
        
            globalStatus["loadscreen"]["overrideWNDW"] := ""
            this.allowExit := restoreAllowExit
            SetTitleMatchMode(restoreTTMM)
        
            return
        }

        return launchHandler(URI)
    }
}

; --- STEAM APPS W/ REQUIRED LAUNCHER TO SKIP ---
class SteamGameProgramWithLauncher extends SteamGameProgram {
    _launcherEXE      := ""   ; exe of launcher application
    _launcherMousePos := []   ; array of positions to click as a double array
    _launcherDelay    := 1000 ; delay before clicking
    
    _launch(URI, args*) {
        global globalStatus

        if (super._launch(URI, args*) = false) {
            return false
        }

        if (this._launcherEXE = "") {
            return
        }

        restoreAllowExit := this.allowExit
        this.allowExit   := true

        ; wait for executable
        while (!WinShown("ahk_exe " this._launcherEXE)) {
            if (this.exists()) {
                return
            }
            else if (this.shouldExit) {
                return false
            }

            Sleep(100)
        }

        ; flatten double array
        mouseArr := []
        loop this._launcherMousePos.Length {
            if (Type(this._launcherMousePos[A_Index]) = "Array") {
                currIndex := A_Index
                loop this._launcherMousePos[currIndex].Length {
                    mouseArr.Push(this._launcherMousePos[currIndex][A_Index])
                }
            }
            else {
                mouseArr.Push(this._launcherMousePos[A_Index])
            }
        }


        globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe " this._launcherEXE

        ; try to skip launcher as long as exectuable is shown
        while (WinShown("ahk_exe " this._launcherEXE)) {
            if (this.exists()) {
                return
            }
            else if (this.shouldExit) {
                return false
            }

            loop (mouseArr.Length / 2) {
                index := ((A_Index - 1) * 2) + 1

                Sleep(this._launcherDelay)

                if (this.exists() || !WinShown("ahk_exe " this._launcherEXE)) {
                    return
                }
                else if (this.shouldExit) {
                    return false
                }

                MouseClick("Left"
                    , percentWidthRelativeWndw(mouseArr[index], "ahk_exe " this._launcherEXE)
                    , percentHeightRelativeWndw(mouseArr[index + 1], "ahk_exe " this._launcherEXE)
                    ,,, "D"
                )
                Sleep(75)
                MouseClick("Left",,,,, "U")
                Sleep(75)
                MouseMove(percentWidth(1), percentHeight(1))    
            }
        }

        this.allowExit := restoreAllowExit
        globalStatus["loadscreen"]["overrideWNDW"] := ""
    }

    ; dank ass bad practice
    exit() {
        if (this._launcherEXE != "" && ProcessExist(this._launcherEXE)) {
            ProcessClose(this._launcherEXE)
        }

        super.exit()
    }
}

; --- OVERRIDES ---
class BioShockHDProgram extends SteamGameProgram {
    _postLaunchDelay := 2000

    _postLaunch() {
        SendSafe("{Enter}")
    }
}

class BlueFireProgram extends SteamGameProgram {
    _fullscreenDelay := 6500
}

class DarkSouls3Program extends SteamGameProgram {
    _fullscreenDelay := 6500
}

class ClustertruckProgram extends SteamGameProgram {
    _postLaunchDelay := 500

    _launch(args*) {
        global globalStatus

        super._launch(args*)

        ; clustertruck's launcher is a garbage piece of shit
        globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe Clustertruck.exe"

        count := 0
        maxCount := 150
        while (!WinExist("ahk_exe Clustertruck.exe")) {
            count += 1
            Sleep(100)
        }

        if (WinExist("ahk_exe Clustertruck.exe")) {
            Sleep(500)

            WinActivate("ahk_exe Clustertruck.exe")
            SendSafe("{Enter}")
        }

        globalStatus["loadscreen"]["overrideWNDW"] := ""
    }
}

class BraidProgram extends SteamGameProgram {
    _postLaunchDelay := 500

    _postLaunch() {
        if (this.checkFullscreen()) {
            Send("!{Enter}")
        }

        Sleep(500)
        super._fullscreen()
    }
}

class UndertaleProgram extends SteamGameProgram {
    _fullscreenDelay := 1000

    _fullscreen() {
        SendSafe("{F4}")
    }
}

; --- OVERRIDES W/ LAUNCHERS ---
class BatmanArkhamProgram extends SteamGameProgramWithLauncher {
    _launcherEXE := "BmLauncher.exe"
    _launcherMousePos := [0.500, 0.666]
}

class SkyrimSEProgram extends SteamGameProgramWithLauncher {
    _launcherEXE := "SkyrimSELauncher.exe"
    _launcherMousePos := [0.925, 0.112]
}

class Fallout3Program extends SteamGameProgramWithLauncher {
    _launcherEXE := "FalloutLauncherSteam.exe"
    _launcherMousePos := [0.922, 0.278]
}

class FalloutNVProgram extends SteamGameProgramWithLauncher {
    _launcherEXE := "FalloutNVLauncher.exe"
    _launcherMousePos := [0.922, 0.278]
}

class Fallout4Program extends SteamGameProgramWithLauncher {
    _launcherEXE := "Fallout4Launcher.exe"
    _launcherMousePos := [0.922, 0.109]
}

class HitmanProgram extends SteamGameProgramWithLauncher {
    _launcherEXE := "Launcher.exe"
    _launcherMousePos := [0.128, 0.621]
}

class SaintsRow3Program extends SteamGameProgramWithLauncher {
    _launcherEXE := "game_launcher.exe"
    _launcherMousePos := [0.250, 0.441]
}

class Witcher2Program extends SteamGameProgramWithLauncher {
    _launcherEXE := "Launcher.exe"
    _launcherMousePos := [0.585, 0.875]
}

class OblivionProgram extends SteamGameProgramWithLauncher {
    _launcherEXE := "OblivionLauncher.exe"
    _launcherMousePos := [0.664, 0.250]
}

class HotlineMiamiProgram extends SteamGameProgramWithLauncher {
    _launcherEXE := "HotlineMiami.exe"
    _launcherMousePos := [0.216, 0.948]
}

class SuperHotProgram extends SteamGameProgramWithLauncher {
    _launcherEXE := "SUPERHOT.exe"
    _launcherMousePos := [[0.205, 0.500], [0.373, 0.833]]
}

class SuperHot2Program extends SteamGameProgramWithLauncher {
    _launcherEXE := "SUPERHOTMCD.exe"
    _launcherMousePos := [[0.497, 0.500], [0.373, 0.833]]
}

class RDR2Program extends SteamGameProgramWithLauncher {
    _launcherEXE := "Launcher.exe"
}

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
        SendSafe("{Enter}")
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