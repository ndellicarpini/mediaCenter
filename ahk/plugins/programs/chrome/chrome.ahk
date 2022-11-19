chromeGetWNDW() {
    retVal := ""
    for item in WinGetList("ahk_exe chrome.exe") {
        if (WinGetTitle("ahk_id " item) != "Picture in picture") {
            retVal := "ahk_id " item
            break
        }
    }

    return retVal
}

chromeExit() {
    global globalRunning

    if (keyboardExists()) {
        closeKeyboard()
    }

    WinClose(globalRunning["chrome"].getWNDW())
}

chromePIP() {
    Send("{Alt Down}p{Alt Up}")
}
