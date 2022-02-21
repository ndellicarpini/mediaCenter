; creates a backup of status & saves it to backup directory
;  status - status obj to backup
;
; returns null
statusBackup(running) {
    global globalStatus

    backup := Map()

    for key, value in MT_STATUS_KEYS {
        backup[key] := getStatusParam(key)
    }
    
    backup["mainRunning"] := Map()
    for key, value in running {
        backup["mainRunning"][key] := value.time
    }

    backupFile := FileOpen("data\backup.bin", "w -rwd")
    backupFile.RawWrite(ObjDump(backup))
    backupFile.Close()
}

; restores status backup & returns proper status object
;  status - status obj to update with restored values
;  programs - program configs parsed in main
; 
; returns status updated with values from backup
statusRestore(running, programs) {
    backup := ObjLoad("data\backup.bin")
    
    for key, value in backup {
        if (key = "mainRunning") {
            for name, time in backup["mainRunning"] {
                createProgram(name, running, programs, false, false, time)
            }
        }
        else {
            setStatusParam(key, value)
        }
    }
}