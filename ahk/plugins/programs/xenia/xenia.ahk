xeniaPause() {
    global globalRunning

    this := globalRunning["xenia"]

    ProcessSuspend(this.getPID())
}

xeniaResume() {
    global globalRunning

    this := globalRunning["xenia"]

    ProcessResume(this.getPID())
}