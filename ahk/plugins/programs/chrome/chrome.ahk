chromeGetWNDW() {
    retVal := ""
    for item in WinGetList("ahk_exe chrome.exe") {
        if (WinShown("ahk_id " item) && WinGetTitle("ahk_id " item) != "Picture in picture") {
            retVal := "ahk_id " item
            break
        }
    }

    return retVal
}

chromeExit() {
    global globalRunning

    currWNDW := globalRunning["chrome"].getWNDW()
    while(currWNDW != "") {
        WinClose(currWNDW)
        Sleep(100)

        currWNDW := globalRunning["chrome"].getWNDW()
    }
}

chromePIP() {
    Send("{Alt Down}p{Alt Up}")
}
