class BioShockHDProgram extends SteamGameProgram {
    _postLaunchDelay := 2000

    _postLaunch() {
        this.send("{Enter}")
    }
}