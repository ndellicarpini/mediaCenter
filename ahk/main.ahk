#SingleInstance Force
#WarnContinuableException Off

#Include 'mclib\confio.ahk'
#Include 'mclib\thread.ahk'
#Include 'mclib\display.ahk'
#Include 'mclib\std.ahk'

; ----- READ GLOBAL CONFIG -----
globalConfig := readConfig("config\global.txt", , "brackets")
globalConfig.cleanAllItems()        

; create thread safe config
c_config := CriticalObject({
    ; generic settings
    monitorW: getDisplaySize(globalConfig.subConfigs["Display"])[1],
    monitorH: getDisplaySize(globalConfig.subConfigs["Display"])[2],
    forceActivateWindow: globalConfig.subConfigs["General"].items["ForceActivateWindow"],
    allowMultiTasking: globalConfig.subConfigs["General"].items["AllowMultiTasking"],
    allowMultiTaskingGame: globalConfig.subConfigs["General"].items["AllowMultiTaskingGame"],
    maxXinput: globalConfig.subConfigs["General"].items["MaxXInputControllers"],
    xinputDLL: globalConfig.subConfigs["General"].items["XInputDLL"],

    ; executables & paths
    homeEXE: globalConfig.subConfigs["Executables"].items["Home"],
    homeDir: globalConfig.subConfigs["Executables"].items["HomeDir"],
    
    browserEXE: globalConfig.subConfigs["Executables"].items["Browser"],
    browserDir:  globalConfig.subConfigs["Executables"].items["BrowserDir"],

    gameLauncherEXE: globalConfig.subConfigs["Executables"].items["GameLauncher"],
    gameLauncherDir: globalConfig.subConfigs["Executables"].items["GameLauncherDir"],

    steamEXE: globalConfig.subConfigs["BGExecutables"].items["Steam"],
    steamDir: globalConfig.subConfigs["BGExecutables"].items["SteamDir"],

    joyToKeyEXE: globalConfig.subConfigs["BGExecutables"].items["JoyToKey"],
    joyToKeyDir: globalConfig.subConfigs["BGExecutables"].items["JoyToKeyDir"],

    ; executable lists from file
    winGameList: readConfig(globalConfig.subConfigs["Lists"].items["WinGameList"], "").items,
    emuGameList: readConfig(globalConfig.subConfigs["Lists"].items["EmulatorList"], "").items,
    loadOverrideList: readConfig(globalConfig.subConfigs["Lists"].items["LoadOverrideList"], "").items,
})

; create thread safe current status of media center
c_status := CriticalObject({
    ; pause all scripting
    pauseScript: false,

    ; current modes
    ; valid modes: [boot, shutdown, restart, home, gamelauncher, game, browser, override, load]
    mode: "",
    pauseMenu: false,
    modifier: {
        override: false,
        multi: false,
    },

    currControllers: [],

    ; current programs running
    currHome: "",
    currGameLauncher: "",
    currGame: "",
    currBrowser: "",

    ; override is either a loadscreen override or something like pause screen browser
    currOverride: "",
})

; create check running program thread
threads := ThreadList.New(ObjPtr(c_config), ObjPtr(c_status))

Sleep(10000)

threads.CloseAllThreads()