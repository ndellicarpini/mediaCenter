desmumeReset() {
    Send("{Ctrl down}")
    SendSafe("r")
    Send("{Ctrl up}")
}

desmumeSaveState(slot) {
    Send("{Shift down}")
    SendSafe("{F1}")
    Send("{Shift up}")
}

desmumeLoadState(slot) {
   SendSafe("{F1}")
}

desmumeFastForward() {
    global globalRunning

    this := globalRunning["desmume"]

    if (this.fastForwarding) {
        Send("{Tab up}")
    }
    else {
        Send("{Tab down}")
    }
}