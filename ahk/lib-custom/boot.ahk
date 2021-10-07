boot(mainConfig) {
    startBoot := false
    for index, value in mainConfig["StartArgs"] {
        
        if (InStr(value, "-b", false)) {
            startBoot := true
            break
        }
    }

    if (startBoot) {
        MsgBox("doin your mom")
    }
}