class SpiderManProgram extends SteamGameProgram {
    _postLaunchDelay := 500

    _postLaunch() {
        this.send("{Enter}")
    }
}