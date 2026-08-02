class KodiProgram extends Program {
    _postLaunchDelay := 0
    _vpnConnected := false
    _vpnSupported := false
    _lastCheckedVPNTime := 0

    _vpnEnableKey := "Enable VPN"
    _vpnDisableKey := "Disable VPN"

    __New(args*) {
        super.__New(args*)

        this._vpnSupported := (this.HasOwnProp("enableVPN") && this.enableVPN != "" 
            && this.HasOwnProp("disableVPN") && this.disableVPN != "" 
            && this.HasOwnProp("checkVPN") && this.checkVPN != "") ? true : false

        ; remove vpn toggle from menu if no vpn cli path specified
        if (!this._vpnSupported) {
            loop this.pauseOrder.Length {
                item := this.pauseOrder[A_Index]

                if (this.pauseOptions.Has(item) && this.pauseOptions[item] = "program.toggleVPN") {
                    this.pauseOrder.RemoveAt(A_Index)
                    break
                }
            }
        }
        ; add fake enable/disable vpn pause options and edit pause order to control which one is shown
        else {
            for key, value in this.pauseOptions {
                if (value = "program.toggleVPN") {
                    togglePos := InStr(StrLower(key), "toggle")
                    if (togglePos) {
                        this._vpnEnableKey := StrReplace(key, SubStr(key, togglePos, 6), "Enable")
                        this._vpnDisableKey := StrReplace(key, SubStr(key, togglePos, 6), "Disable")
                    }

                    this.pauseOptions[this._vpnEnableKey] := "program.toggleVPN"
                    this.pauseOptions[this._vpnDisableKey] := "program.toggleVPN"
                }
            }
        }
    }

    _exists(args*) {
        global globalRunning
        global globalStatus
        global globalGuis

        retVal := super._exists(args*)

        ; check and disable bigbox audio if bigbox in background
        if (retVal && globalRunning.Has(this.id) && this._vpnSupported && this._vpnConnected && ((A_TickCount - this._lastCheckedVPNTime) > 1000)
            && (globalStatus["currProgram"]["id"] != this.id || globalStatus["suspendScript"] || globalStatus["desktopmode"])) {

            this._disableVPN()
            this._lastCheckedVPNTime := A_TickCount
        }

        return retVal
    }

    _fullscreen() {
        this.send("\")
    }

    _postLaunch() {
        if (!this._vpnSupported) {
            return   
        }

        this._checkVPN()
        return
    }

    _postExit() {
        if (!this._vpnSupported) {
            return   
        }

        this._checkVPN()
        if (this._vpnConnected) {
            Sleep(500)
            this._disableVPN()
        }
    } 

    toggleVPN() {
        this._checkVPN()
        Sleep(100)

        if (this._vpnConnected) {
            this._disableVPN()
        }
        else {
            this._enableVPN()
        }
    }

    ; custom function
    reload() {
        this.exit(false)
        Sleep(500)
        createProgram("kodi")
    }

    _checkVPN() {
        if (!this._vpnSupported) {
            return
        }

        this._vpnConnected := runFunction(this.checkVPN)
        this._updatePauseOptions()

        return this._vpnConnected
    }

    _enableVPN() {
        if (!this._vpnSupported) {
            return
        }

        runFunction(this.enableVPN)
        Sleep(500)
        this._checkVPN()
    }

    _disableVPN() {
        if (!this._vpnSupported) {
            return
        }

        runFunction(this.disableVPN)
        Sleep(500)
        this._checkVPN()
    }

    _updatePauseOptions() {
        loop this.pauseOrder.Length {
            item := this.pauseOrder[A_Index]

            if (this.pauseOptions.Has(item) && this.pauseOptions[item] = "program.toggleVPN") {
                this.pauseOrder[A_Index] := (this._vpnConnected) ? this._vpnDisableKey : this._vpnEnableKey
                break
            }
        }
    }
}