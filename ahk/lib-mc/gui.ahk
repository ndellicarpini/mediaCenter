; returns an array [w, h] of the display requested in global config
;  monitorNum - which monitor should be used for everything
;
; returns an array [monitorW, monitorH] of monitorNum
getDisplaySize(monitorNum) {
    MonitorGet(monitorNum, ML, MT, MR, MB)

    monitorH := Floor(Abs(MB - MT))
    monitorW := Floor(Abs(MR - ML))

    return [monitorW, monitorH]
}