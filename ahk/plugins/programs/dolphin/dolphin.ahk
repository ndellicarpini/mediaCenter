dolphinSaveState(slot) {
    Send("{Shift down}")
    Sleep(100)
    SendSafe("{F1}")
    Sleep(100)
    Send("{Shift up}")
}

dolphinLoadState(slot) {
    SendSafe("{F1}")
}

dolphinFastForward() {
    global globalRunning

    this := globalRunning["dolphin"]

    if (this.fastForwarding) {
        Send("{Tab up}")
    }
    else {
        Send("{Tab down}")
    }
}