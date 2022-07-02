; TODO - REMEBER TO DOCUMENT SOMEWHERE THAT RETURNING -1 ENDS THE FUNCTION

; nvidia shadow play (USES WAY TO MUCH GPU - NEED TO TEST)
instantReplay() {
    return { title: "Save Instant Replay", function: "Send !{F10}"}
}

; --- KODI ---
; kodi only properly minimizes if its active?
kodiMinimize() {
    WinActivate("Kodi")
    Sleep(200)
    WinMinimize("Kodi")

    return -1
}

kodiExit() {
    WinClose("Kodi")
    Sleep(5000)
}

; --- CHROME ---
chromeExit() {
    global globalRunning
    global globalGuis

    if (WinShown("On-Screen Keyboard")) {
        WinClose("On-Screen Keyboard")
    }

    WinClose(globalRunning["chrome"].getWND())
}

chromeRestore() {
    if (WinShown("On-Screen Keyboard")) {    
        return -1
    }
}

chromeControls() {
    MsgBox("having sex with your moother")
}

chromePIP() {
    global globalRunning

    this := globalRunning["chrome"]
        
    Send("{Alt Down}p{Alt Up}")
        
    for key, value in this.pauseOptions {
        if (InStr(key, "Picture-in-Picture")) {
            newKey := ""

            if (InStr(key, "Enable")) {
                newKey := StrReplace(key, "Enable", "Disable")                    
            }
            else {
                newKey := StrReplace(key, "Disable", "Enable")
            }

            this.pauseOptions[newKey] := value
            this.pauseOptions.Delete(key)

            loop this.pauseOrder.Length {
                if (this.pauseOrder[A_Index] = key) {
                    this.pauseOrder[A_Index] := newKey
                    break
                }
            }

            break
        }
    }
}

; --- BIG BOX --- 
; don't restore w/ starting up
bigBoxRestore() {
    if (WinShown("LaunchBox Game Startup")) {
        return -1
    }
}