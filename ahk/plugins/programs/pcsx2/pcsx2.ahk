pcsx2Exit() {
    global globalRunning

    WinClose(globalRunning["pcsx2"].getWND())
    Sleep(100)
    WinClose(globalRunning["pcsx2"].getWND())
}

pcsx2SaveState(slot) {
    SendSafe("{F1}")
}

pcsx2LoadState(slot) {
    SendSafe("{F3}")
}