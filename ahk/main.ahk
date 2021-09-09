#SingleInstance Force
#WarnContinuableException Off

#Include mclib\confio.ahk
#Include 'mclib\display.ahk'

; ----- READ GLOBAL CONFIG -----
globalConfig := readConfig("config\global.txt", , "brackets")
globalConfig.cleanAllItems()

; get monitor sizing
temp := getDisplaySize(globalConfig.subConfigs["Display"])
monitorW := temp[1]
monitorH := temp[2]

MsgBox(monitorH)
