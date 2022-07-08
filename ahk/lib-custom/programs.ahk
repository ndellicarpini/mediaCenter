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

kodiExit() {
    WinClose("Kodi")
    Sleep(5000)
}

; --- CHROME ---
chromeExit() {
    global globalRunning
    ; global globalGuis

    if (WinShown("On-Screen Keyboard")) {
        WinClose("On-Screen Keyboard")
    }

    WinClose(globalRunning["chrome"].getWND())
}

chromeRestore() {
    ; don't restore if msft on-screen keyboard exists
    if (WinShown("On-Screen Keyboard")) {    
        return -1
    }
}

chromePIP() {
    Send("{Alt Down}p{Alt Up}")
}

; --- BIG BOX --- 
bigBoxRestore() {
    ; stop while start up screen exists
    while (WinShown("LaunchBox Game Startup")) {
        Sleep(100)
    }
}