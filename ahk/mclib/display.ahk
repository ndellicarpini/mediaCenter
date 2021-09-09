; returns an array [w, h] of the display requested in global config
;  displayConfig - Config from display section of global config
;
; returns an array [monitorW, monitorH] 
getDisplaySize(displayConfig) {
    monitorW := displayConfig.items["Height"]
    monitorH := displayConfig.items["Width"]

    MonitorGet(displayConfig.items["MonitorNum"], ML, MT, MR, MB)

    if (monitorH == 0) {
        monitorH := Floor(Abs(MB - MT))
    }

    if (monitorW == 0) {
        monitorW := Floor(Abs(MR - ML))
    }

    return [monitorW, monitorH]
}