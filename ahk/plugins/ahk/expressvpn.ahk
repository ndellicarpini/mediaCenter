expressVPNConnect() {
    global globalConfig

    vpnPath := validateDir(globalConfig["ExpressVPN"]["Path"])
    cliEXE := vpnPath . "services\ExpressVPN.CLI.exe"

    return RunCMD(cliEXE . " connect")
}

expressVPNDisconnect() {
    global globalConfig

    vpnPath := validateDir(globalConfig["ExpressVPN"]["Path"])
    cliEXE := vpnPath . "services\ExpressVPN.CLI.exe"

    return RunCMD(cliEXE . " disconnect")
}

expressVPNConnected() {
    global globalConfig

    vpnPath := validateDir(globalConfig["ExpressVPN"]["Path"])
    cliEXE := vpnPath . "services\ExpressVPN.CLI.exe"

    results := RunCMD(cliEXE . " status")
    return !InStr(StrLower(results), "not connected")
}