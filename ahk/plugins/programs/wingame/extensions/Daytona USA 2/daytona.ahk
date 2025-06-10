class SuperModelProgram extends WinGameProgram {
    _launch(game, args*) {
        global DEFAULT_MONITOR
        monitorInfo := getMonitorInfo(DEFAULT_MONITOR)

        newArgs := ObjDeepClone(args)
        newArgs.Push("-res=" . monitorInfo[3] . "," . monitorInfo[4])
        super._launch(game, newArgs*)
    }
}