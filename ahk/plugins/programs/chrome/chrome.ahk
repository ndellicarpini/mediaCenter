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
