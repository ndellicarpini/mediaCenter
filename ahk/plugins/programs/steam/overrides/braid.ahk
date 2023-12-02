class BraidProgram extends SteamGameProgram {
    _postLaunchDelay := 500

    _postLaunch() {
        if (this.checkFullscreen()) {
            Send("!{Enter}")
        }

        Sleep(500)
        super._fullscreen()
    }
}