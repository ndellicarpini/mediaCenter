#SingleInstance Force
#WarnContinuableException Off

#Include 'mclib\confio.ahk'
#Include 'mclib\display.ahk'

; ----- READ GLOBAL CONFIG -----
globalConfig := readConfig("config\global.txt", , "brackets")
globalConfig.cleanAllItems()

; get monitor sizing
temp := getDisplaySize(globalConfig.subConfigs["Display"])
monitorW := temp[1]
monitorH := temp[2]

ForceActivateWindow :=   globalConfig.subConfigs["General"].items["ForceActivateWindow"]
AllowMultiTasking :=     globalConfig.subConfigs["General"].items["AllowMultiTasking"]
AllowMultiTaskingGame := globalConfig.subConfigs["General"].items["AllowMultiTaskingGame"]
XInputDLL :=             globalConfig.subConfigs["General"].items["XInputDLL"]

; get game executable lists
gameConfigs := globalConfig.subConfigs["Games"].items

critGameObj := {}
critGameObj.currGame := ""
critGameObj.winGameList := readConfig(gameConfigs["WinGameList"], "").items
critGameObj.emuGameList := readConfig(gameConfigs["EmulatorList"], "").items

; need critical object to have between thread info - doesn't seem to add much overhead
critGameList := CriticalObject(critGameObj)

; create check game running thread
checkGameThread := AhkThread("
(
    #Include 'mclib\games.ahk'
    critGameList := CriticalObject(A_Args[1])
    Loop {
        critGameList.currGame := checkGameEXE(critGameList.winGameList, critGameList.emuGameList)
        Sleep(100)
    }
)"
, ObjPtr(critGameList) . "")


checkGameThread.ahkTerminate()