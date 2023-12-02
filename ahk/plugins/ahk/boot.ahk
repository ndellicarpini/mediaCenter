; boot
customBoot() {
    setLoadScreen()

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
        createProgram(["steam", "wait=false"], true, false)
    }
    
    resetLoadScreen()
}