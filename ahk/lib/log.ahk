

; writes to the log
;  text - text to write
;  prefix - prefix for log line
;
; returns null
writeLog(text, prefix := "") {
    if (!DirExist("data\")) {
        DirCreate("data\")
    }
    if (!DirExist("data\logs")) {
        DirCreate("data\logs")
    }

    if (FileExist("data\logs\log.txt")) {
        modifiedTime := FileGetTime("data\logs\log.txt", "M")
        if (SubStr(modifiedTime, 1, 8) != SubStr(A_Now, 1, 8)) {
            FileMove("data\logs\log.txt", "data\logs\log." . FormatTime(modifiedTime, "yyyy-MM-dd") . ".txt", true)
        }
    }

    newLine := "[" . FormatTime(, "MM-dd-yyyy HH:mm:ss") . ((prefix != "") ? ("] " . prefix . " | ") : "] ") . text . "`r`n"
    FileAppend(newLine, "data\logs\log.txt")
}

; writes an error to the log, designed to be used with OnError
; https://www.autohotkey.com/docs/v2/lib/OnError.htm
;
; returns -1 -> error messages will not be shown
writeErrorLog(thrownError, thrownMode := "Return") {
    global globalStatus

    prefix := "ERROR"
    if (StrLower(thrownMode) = "exit") {
        prefix := "UNCAUGHT ERROR"
    }
    else if (StrLower(thrownMode) = "exitapp") {
        prefix := "FATAL ERROR"
    }

    ; errorMessage := thrownError.File . ":" . thrownError.Line . " - " . thrownError.Message
    errorMessage := thrownError.File . ":" . thrownError.Line . " - " . thrownError.Message . " | " . thrownError.Stack
    writeLog(errorMessage, prefix)

    if (globalStatus["lastError"] = errorMessage) {
        globalStatus["input"]["buffer"].Push(
            "createInterface `"choice`" true `"`" `"ERROR: " . errorMessage "`" `"Wait`" `"`" `"`" `"Exit`" `"ExitApp`" `"FF0000`""
        )
    }

    globalStatus["lastError"] := errorMessage
    if (StrLower(thrownMode) = "exitapp") {
        Run(A_ScriptDir . "\" . "startMain.cmd -quiet -backup", A_ScriptDir, "Hide")
    }

    return -1
}