; TODO - REMEBER TO DOCUMENT SOMEWHERE THAT RETURNING -1 ENDS THE FUNCTION

; nvidia shadow play (USES WAY TO MUCH GPU - NEED TO TEST)
instantReplay() {
    return { title: "Save Instant Replay", function: "Send !{F10}"}
}

; --- KODI ---
kodiMinimize() {
    ; kodi only properly minimizes if its active?
    WinActivate("Kodi")
    Sleep(200)
    WinMinimize("Kodi")

    return -1
}

kodiReload() {
    global globalRunning

    globalRunning["kodi"].exit()
    Sleep(500)
    ResetScript()
}

; --- CHROME ---
chromeExit() {
    global globalRunning

    if (keyboardExists()) {
        closeKeyboard()
    }

    WinClose(globalRunning["chrome"].getWND())
}

chromePIP() {
    Send("{Alt Down}p{Alt Up}")
}

; --- BIG BOX --- 
bigBoxRestore() {
    ; stop while start up screen exists
    if (WinShown("LaunchBox Game Startup")) {
        while (WinShown("LaunchBox Game Startup")) {
            Sleep(5)
        }

        return -1
    }
}