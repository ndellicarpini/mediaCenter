citraSaveState(slot) {
    Send("{Ctrl down}")
    SendSafe("c")
    Send("{Ctrl up}")
}

citraLoadState(slot) {
    Send("{Ctrl down}")
    SendSafe("v")
    Send("{Ctrl up}")
}

citraFastForward() {
    Send("{Ctrl down}")
    SendSafe("z")
    Send("{Ctrl up}")
}