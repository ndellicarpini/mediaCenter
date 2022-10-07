; boot
customBoot() {
    if (!ProcessExist("explorer.exe")) {
        Run "explorer.exe"

        count := 0
        maxCount := 50
        while (count < maxCount) {
            activateLoadScreen()
            
            count += 1
            Sleep(50)
        }
    }

    if (!ProcessExist("steam.exe")) {
        createProgram("steam", true, false)
    }
    
    resetLoadScreen()
}