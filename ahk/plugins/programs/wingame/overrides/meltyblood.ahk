class MBAAProgram extends WinGameProgram {
    _postLaunchDelay := 500

    _postLaunch() {
        this.send("{Enter}")
    }
}