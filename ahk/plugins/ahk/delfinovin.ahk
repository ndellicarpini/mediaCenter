startDelfinovin(loopCount := 0) {
    global globalConfig

    if (loopCount >= 3) {
        return false
    }

    stopDelfinovin()

    gcnAdapterPath := validateDir(globalConfig["Delfinovin"]["Path"])
    gcnAdapterEXE := gcnAdapterPath .  "Delfinovin.exe"

    if (FileExist(gcnAdapterEXE)) {
        try {
            RunAsAdmin(gcnAdapterEXE,, gcnAdapterPath)
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
        else {
            startDelfinovin(loopCount + 1)
        }
    }
}

stopDelfinovin() {
    count := 0
    maxCount := 5
    while (ProcessExist("Delfinovin.exe") && count < maxCount) {
        ProcessClose("Delfinovin.exe")

        Sleep(3000)
        count += 1
    }

    Sleep(1000)

    if (ProcessExist("Delfinovin.exe")) {
        ProcessKill("Delfinovin.exe")
    }
}