; creates a backup of status & saves it to backup directory
;  status - status obj to backup
;
; returns null
statusBackup(status, running) {
    backup := Map()

    backup["pause"] := status["pause"]
    backup["suspendScript"] := status["suspendScript"]
    backup["currProgram"]  := status["currProgram"]
    backup["overrideProgram"] := status["overrideProgram"]
    backup["loadShow"] := status["loadShow"]
    backup["loadText"] := status["loadText"]
    backup["errorShow"] := status["errorShow"]
    backup["errorHWND"] := status["errorHWND"]
    
    if (running.Has("keys") && running["keys"] != "") {
        backup["openPrograms"] := Map()
        for key in StrSplit(running["keys"], ",") {
            backup["openPrograms"][key] := running[key].time
        }
    }

    backupFile := FileOpen("data\status.bin", "w -rwd")
    backupFile.RawWrite(ObjDump(backup))
    backupFile.Close()
}

; restores status backup & returns proper status object
;  status - status obj to update with restored values
;  programs - program configs parsed in main
; 
; returns status updated with values from backup
statusRestore(status, running, programs) {
    backup := ObjLoad("data\status.bin")
    
    for key, value in backup {
        if (key = "openPrograms") {
            for name, time in backup["openPrograms"] {
                createProgram(name, status, running, programs, false, false, time)
            }
        }
        else {
            status[key] := value
        }
    }

    return status
}