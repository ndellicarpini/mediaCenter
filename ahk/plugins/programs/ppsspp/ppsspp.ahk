ppssppReset() {
    Send("{Ctrl down}")
    SendSafe("b")
    Send("{Ctrl up}")
}

ppssppSaveState(slot) {
    SendSafe("{F1}")
}

ppssppLoadState(slot) {
    SendSafe("{F3}")
}

ppssppFastForward() {
    global globalRunning

    this := globalRunning["ppsspp"]

    if (this.fastForwarding) {
        Send("{Tab up}")
    }
    else {
        Send("{Tab down}")
    }
}