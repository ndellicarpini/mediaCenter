boot() {
    if (!ProcessExist("explorer.exe")) {
        Run "explorer.exe"

        count := 0
        maxCount := 20
        while (count < maxCount) {
            updateLoadScreen()
            
            count += 1
            Sleep(100)
        }

        resetLoadScreen()
    }
}