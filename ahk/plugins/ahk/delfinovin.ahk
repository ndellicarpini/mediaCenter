startDelfinovin() {
    global globalConfig

    gcnAdapterPath := validateDir(globalConfig["Delfinovin"]["Path"])
    gcnAdapterEXE := gcnAdapterPath .  "Delfinovin.exe"

    if (FileExist(gcnAdapterEXE)) {
        try {
            RunAsUser(gcnAdapterEXE, "", gcnAdapterPath)
        }
        catch {
            return false
        }

        count := 0
        maxCount := 100
        while (!WinShown("Delfinovin") && count < maxCount) {
            Sleep(100)
            count += 1
        }

        if (count < maxCount) {
            Sleep(2000)
        }
    }
}

stopDelfinovin() {
    count := 0
    maxCount := 5
    while (ProcessExist("Delfinovin.exe") && count < maxCount) {
        WinClose("ahk_exe Delfinovin.exe")

        Sleep(3000)
        count += 1
    }
}