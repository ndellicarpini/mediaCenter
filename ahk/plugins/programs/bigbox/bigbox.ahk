bigBoxRestore() {
    ; stop while start up screen exists
    if (WinShown("LaunchBox Game Startup")) {
        while (WinShown("LaunchBox Game Startup")) {
            Sleep(5)
        }

        return -1
    }
}