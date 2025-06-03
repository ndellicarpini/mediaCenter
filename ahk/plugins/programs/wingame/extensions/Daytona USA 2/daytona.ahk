class SuperModelProgram extends WinGameProgram {
    _launch(game, args*) {
        global MONITOR_W
        global MONITOR_H

        newArgs := ObjDeepClone(args)
        newArgs.Push("-res=" . MONITOR_W . "," . MONITOR_H)
        super._launch(game, newArgs*)
    }
}