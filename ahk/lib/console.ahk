; initializes the attached command line interface to run commands
;
; returns null
initConsole() {    
    restoreDHW := A_DetectHiddenWindows
    DetectHiddenWindows("On")

    Run(A_ComSpec,, "Hide", &runPID)
    WinWait("ahk_pid " runPID)
    DllCall("kernel32\AttachConsole", "UInt", runPID)
    
    instance := ComObject("WScript.Shell")
    DetectHiddenWindows(restoreDHW)

    return Map(
        "instance", instance,
        "pid", runPID
    )
}

; destroys the attached command line interface if it exists
;  pid - pid of shell window
;
; returns null
destroyConsole(initResults) {
    restoreDHW := A_DetectHiddenWindows
    DetectHiddenWindows("On")

    initResults["instance"] := ""
    if (ProcessExist(initResults["pid"])) {
        DllCall("kernel32\FreeConsole")
        WinClose("ahk_pid " initResults["pid"])
    }
    if (ProcessExist(initResults["pid"])) {
        ProcessKill(initResults["pid"])
    }

    DetectHiddenWindows(restoreDHW)
}

; runs a command line function
;  command - command to run
;
; returns output of command
RunCMD(command) {
    initResults := initConsole()

    try {
        execResult := initResults["instance"].Exec(command)
    }
    catch {
        execResult := initResults["instance"].Exec(command)
    }

    retVal := execResult.StdOut.ReadAll()
    destroyConsole(initResults)
    return retVal
}

; runs a Powershell command
;  command - command to run
;  formatTable - simplify console size issues by converting output to a table first
;
; returns output of command
RunPowershell(command, formatTable := True) {
    tableString := "| Format-Table -AutoSize | Out-String -Stream -Width 2147483647"
    return RunCMD("PowerShell.exe -Command `"" . command . (formatTable ? tableString : "") . "`"")
}