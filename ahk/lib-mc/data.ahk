; creates a backup of status & saves it to backup directory
;  status - status obj to backup
;
; returns null
statusBackup(status) {
    backup := Map()

    backup["pause"] := status["pause"]
    backup["suspendScript"] := status["suspendScript"]
    backup["currProgram"]  := status["currProgram"]
    backup["overrideProgram"] := status["overrideProgram"]
    backup["load"] := Map()
    backup["load"]["show"] := status["load"]["show"]
    backup["load"]["text"] := status["load"]["text"]
    
    if (status["openPrograms"].Has("keys") && status["openPrograms"]["keys"] != "") {
        backup["openPrograms"] := Map()
        for key in StrSplit(status["openPrograms"]["keys"], ",") {
            backup["openPrograms"][key] := status["openPrograms"][key].time
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
statusRestore(status, programs) {
    backup := ObjLoad("data\status.bin")
    
    for key, value in backup {
        if (key = "openPrograms") {
            for name, time in backup["openPrograms"] {
                status := createProgram(name, status, programs, false, false, time)
            }
        }
        else {
            status[key] := value
        }
    }

    return status
}