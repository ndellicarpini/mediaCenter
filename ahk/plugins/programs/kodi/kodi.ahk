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
}