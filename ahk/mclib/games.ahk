; takes a variable amount of game maps and returns the process exe if its running
;  games* - any amount of game lists
;
; return either "" if the process is not running, or the name of the process
checkGameEXE(games*) {
    for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process") {
        for gameList in games {
            if (gameList.Has(process.Name)) {
                return process.Name
            }
        }
    }

    return ""
}