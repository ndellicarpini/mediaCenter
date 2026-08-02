class MinecraftProgram extends WinGameProgram {
    _waitingRestoreAllTimer := false
    _windowCount := 0
    _forceActivateAll := false

    _launch(game, args*) {
        if (!this.HasOwnProp("multiInstance")) {
            return super._launch(game, args*)
        }

        global globalInputConfigs
        global globalInputStatus

        ; force no fullscreen
        this.requireFullscreen := false

        try {
            pathArr := StrSplit(game, "\")
            exe := pathArr.RemoveAt(pathArr.Length)
            path := LTrim(joinArray(pathArr, "\"), '"' . '"')
            this.dir := [path]

            numConnected := 0

            for key, value in globalInputConfigs {
                if (!globalInputStatus.Has(key)) {
                    continue
                }

                loop globalInputStatus[key].length {
                    device := globalInputStatus[key][A_Index]
                    if (device["connected"]) {
                        numConnected += 1
                    }
                }
            }

            activeInstances := []
            loop numConnected {
                activeInstances.Push(this.multiInstance[A_Index])
            }    
            if (activeInstances.Length = 0) {
                activeInstances.Push(this.multiInstance[1])
            }
            
            instancePaths := activeInstances.Map((val) => validateDir(validateDir(path) . "instances\" . val))

            index := 1
            for instance in instancePaths {
                splitscreenConfig := instance . "minecraft\config\splitscreen.properties"
                if (!FileExist(splitscreenConfig)) {
                    continue
                }

                currConfig := Config(splitscreenConfig)
                if (activeInstances.Length = 1) {
                    currConfig.data["mode"] := "FULLSCREEN"
                }
                else if (activeInstances.Length = 2) {
                    if (index = 1) {
                        currConfig.data["mode"] := "LEFT"
                    }
                    else if (index = 2) {
                        currConfig.data["mode"] := "RIGHT"
                    }
                }
                else if (activeInstances.Length = 3) {
                    if (index = 1) {
                        currConfig.data["mode"] := "TOP_LEFT"
                    }
                    else if (index = 2) {
                        currConfig.data["mode"] := "TOP_RIGHT"
                    }
                    else if (index = 3) {
                        currConfig.data["mode"] := "BOTTOM"
                    }
                }
                else if (activeInstances.Length > 3) {
                    if (index = 1) {
                        currConfig.data["mode"] := "TOP_LEFT"
                    }
                    else if (index = 2) {
                        currConfig.data["mode"] := "TOP_RIGHT"
                    }
                    else if (index = 3) {
                        currConfig.data["mode"] := "BOTTOM_LEFT"
                    }
                    else if (index = 4) {
                        currConfig.data["mode"] := "BOTTOM_RIGHT"
                    }
                }

                currConfig.write()
                Sleep(150)

                instanceArr := StrSplit(Trim(instance, "\"), "\")
                RunAsUser(game, ["-l " . instanceArr[instanceArr.Length], args*], path)
                Sleep(500)

                index += 1
            }

            return
        }
        catch {
            return false
        }
    }
        
    _restore() {
        if (this.exists() && !ProcessExist("javaw.exe")) {
            return true
        }

        wndws := WinGetList("ahk_exe javaw.exe")
        numWNDWs := 0

        anyWNDWActive := false
        for wndw in wndws {
            if (!WinShown(wndw) || !InStr(WinGetProcessPath(wndw), this.dir[1])) {
                continue
            }

            numWNDWs += 1
            if (WinActive(wndw)) {
                anyWNDWActive := true
            }
        }

        if (!anyWNDWActive || this._windowCount != numWNDWs || this._forceActivateAll) {
            RestoreAll()
        }

        this._windowCount := numWNDWs
        ; iterate and restore all player windows every 10s
        if (!this._waitingRestoreAllTimer) {
            this._waitingRestoreAllTimer := true
            SetTimer(RestoreAll, Neg(10000))
        }

        return true

        RestoreAll() {
            this._waitingRestoreAllTimer := false
            this._forceActivateAll := false
            if (!this.exists() || this._currShownEXE = "" || this.shouldExit 
                || globalStatus["currProgram"]["id"] != this.id || globalStatus["suspendScript"] || globalStatus["desktopmode"]) {
                return
            }

            wndws := WinGetList("ahk_exe javaw.exe")
            for wndw in wndws {
                if (WinShown(wndw) && InStr(WinGetProcessPath(wndw), this.dir[1])) {
                    try WinActivateForeground(wndw)
                    Sleep(500)
                }
            }

            return
        }
    }

    _pause() {
        this._forceActivateAll := true
        super._pause()
    }

    _exit() {
        wndws := WinGetList("ahk_exe javaw.exe")
        for wndw in wndws {
            if (WinShown(wndw) && InStr(WinGetProcessPath(wndw), this.dir[1])) {
                WinClose(wndw)
                Sleep(500)
            }
        }

        super._exit()
    }
}