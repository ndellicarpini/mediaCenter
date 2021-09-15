#SingleInstance Force
#WarnContinuableException Off

#Include 'lib-mc\confio.ahk'
#Include 'lib-mc\thread.ahk'
#Include 'lib-mc\display.ahk'
#Include 'lib-mc\std.ahk'

; might need to figure out dynamic includes uhhhhhh yut oh

; ----- READ GLOBAL CONFIG -----
globalConfig := readGlobalConfig()

; globalConfigObj := {
;     ; generic settings (added to critical object manually)
;     ; ForceActivateWindow: globalConfig.subConfigs["General"].items["ForceActivateWindow"],
;     ; AllowMultiTasking: globalConfig.subConfigs["General"].items["AllowMultiTasking"],
;     ; AllowMultiTaskingGame: globalConfig.subConfigs["General"].items["AllowMultiTaskingGame"],
;     ; MaxXInput: globalConfig.subConfigs["General"].items["MaxXInputControllers"],
;     ; XinputDLL: globalConfig.subConfigs["General"].items["XInputDLL"],
;     ; PriorityOrder: globalConfig.subConfigs["General"].items["PriorityOrder"],

;     ; MonitorW: getDisplaySize(globalConfig.subConfigs["Display"])[1],
;     ; MonitorH: getDisplaySize(globalConfig.subConfigs["Display"])[2],

;     ; EnableBoot: globalConfig.subConfigs["Boot"].items["EnableBoot"],
;     ; BootScript: globalConfig.subConfigs["Boot"].items["BootScript"],
; }

; globalStatusObj := {
;     ; pause all scripting
;     pauseScript: false,

;     ; current modes
;     ; valid modes: [boot, shutdown, restart, home, gamelauncher, game, browser, override, load]
;     mode: "",
;     pauseMenu: false,
;     modifier: {
;         override: false,
;         multi: false,
;     },

;     currControllers: [],
; }

globalConfigObj := Map()

globalStatusObj := Map()

globalStatusObj["paused"] := false
globalStatusObj["mode"] := ""
globalStatusObj["currControllers"] := false

globalStatusObj["modifier"] := Map()
globalStatusObj["modifier"]["override"] := false
globalStatusObj["modifier"]["multi"] := false

globalStatusObj["suspendScript"] := false

for key, value in globalConfig.subConfigs {
    configObj := Map()
    statusObj := Map()
    
    if (key = "Monitor") {
        temp := getDisplaySize(globalConfig.subConfigs["Display"])
        configObj["MonitorW"] := temp[1]
        configObj["MonitorH"] := temp[2]
        
        continue
    }

    for key2, value2, in value.items {
        if (value2 = "") {
            continue
        }

        if (InStr(key, "List")) {
            configObj[key2] := readConfig(value2, "").items
        }
        else {
            configObj[key2] := value2
            
            if (InStr(key, "Executables") && !InStr(key2, "Dir")) {
                statusObj[key2] := ""
            }
        }
    }

    globalConfigObj[key] := configObj

    ; check if executables in list are running
    if (InStr(key, "Executables")) {
        globalStatusObj[("curr" . key)] := statusObj
    }
}

; add currGame to statusObj, kinda weird but i think it could work
if (globalStatusObj.Has("currExecutables") && globalConfigObj.Has("ListExecutables")) {
    for key, value in globalConfigObj["ListExecutables"] {
        globalStatusObj["currExecutables"][(StrSplit(key, "_")[1])] := ""
    }
}

; create thread safe global config
c_config := CriticalObject(globalConfigObj)

; create thread safe current status
c_status := CriticalObject(globalStatusObj)

; pre running program thread intialize xinput

; after xinput run boot script

; create check running program thread
threads := ThreadList.New(ObjPtr(c_config), ObjPtr(c_status))

; big time crash issue
Loop {
    MsgBox(CriticalObject(ObjPtr(c_status))["currExecutables"]["Browser"])
}

threads.CloseAllThreads()