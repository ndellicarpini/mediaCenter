; cleans up gui config & sets default theming values if not provided in the config
;
; returns null
setGUIConstants() {
    global globalConfig

    global DEFAULT_MONITOR
    global SIZE   
    global FONT
    global FONT_COLOR
    global COLOR1
    global COLOR2
    global COLOR3 

    setInterfaceOverrides()
    if (!globalConfig.Has("GUI")) {
        return
    }

    DEFAULT_MONITOR := (globalConfig["GUI"].Has("MonitorNum") && globalConfig["GUI"]["MonitorNum"] != "") ? globalConfig["GUI"]["MonitorNum"] : 0
    if (DEFAULT_MONITOR <= 0) {
        DEFAULT_MONITOR := MonitorGetPrimary()
    }
    
    SIZE := (globalConfig["GUI"].Has("SizeMultiplier") && globalConfig["GUI"]["SizeMultiplier"] != "")
        ? globalConfig["GUI"]["SizeMultiplier"] : 1
    
    FONT := (globalConfig["GUI"].Has("Font")) ? globalConfig["GUI"]["Font"] : ""

    FONT_COLOR := (globalConfig["GUI"].Has("FontColor") && RegExMatch(globalConfig["GUI"]["FontColor"], "U)#[a-fA-F0-9]{6}"))
        ? StrReplace(globalConfig["GUI"]["FontColor"], "#") : "ffffff"

    COLOR1 := (globalConfig["GUI"].Has("PrimaryColor") && RegExMatch(globalConfig["GUI"]["PrimaryColor"], "U)#[a-fA-F0-9]{6}"))
        ? StrReplace(globalConfig["GUI"]["PrimaryColor"], "#") : "000000"

    COLOR2 := (globalConfig["GUI"].Has("SecondaryColor") && RegExMatch(globalConfig["GUI"]["SecondaryColor"], "U)#[a-fA-F0-9]{6}"))
        ? StrReplace(globalConfig["GUI"]["SecondaryColor"], "#") : "1d1d1d"

    COLOR3 := (globalConfig["GUI"].Has("SelectionColor") && RegExMatch(globalConfig["GUI"]["SelectionColor"], "U)#[a-fA-F0-9]{6}"))
        ? StrReplace(globalConfig["GUI"]["SelectionColor"], "#") : "3399ff"
}

; gets cumulative info for all monitors
;
; returns array of [x, y, w, h]
getAllMonitorInfo() {
    return [SysGet(76), SysGet(77), SysGet(78), SysGet(79)]
}

; gets monitor info for specified monitor
;  monitorNum - monitor to get info for
;
; returns array of [x, y, w, h]
getMonitorInfo(monitorNum) {
    MonitorGet(monitorNum, &ML, &MT, &MR, &MB)
    return [ML, MT, Floor(Abs(MR - ML)), Floor(Abs(MB - MT))]
}

; sets global interface classes from overrides in global.cfg
;
; returns null
setInterfaceOverrides() {
    global globalConfig
    global INTERFACES

    if (!globalConfig.Has("Overrides")) {
        return
    }

    for key, value in INTERFACES {
        if (globalConfig["Overrides"].Has(key)) {
            INTERFACES[key]["class"] := globalConfig["Overrides"][key]
        }
    }
}

; gets the proper width in pixels based on pixel size of screen
;  width - percentage of the window width
;  wndw - wndw title to get screen pixels from
;  useDPI - whether or not to apply the screen's dpi
;
; returns proper size in pixels
percentWidthRelativeWndw(width, wndw, useDPI := false) {
    WinGetPos(&X, &Y, &W, &H, wndw)

    return X + ((width * ((useDPI) ? (A_ScreenDPI / 96) : 1)) * W) 
}

; gets the proper height in pixels based on pixel size of screen
;  height - percentage of the window height
;  wndw - wndw title to get screen pixels from
;  useDPI - whether or not to apply the screen's dpi
;
; returns proper size in pixels
percentHeightRelativeWndw(height, wndw, useDPI := false) {
    WinGetPos(&X, &Y, &W, &H, wndw)
    
    return Y + ((height * ((useDPI) ? (A_ScreenDPI / 96) : 1)) * H)
}

; gets a gui object with the specified wintitle
;  title - title of gui window
;
; returns gui object from title
getGUI(title) {
    retGui := ""

    try {
        hwnd := WinGetID(title)
        retGui := GuiFromHwnd(hwnd)
    }

    return retGui
}

; gets an asset's path based on the name of the asset & the current AssetDir
;  asset - asset name / path to get (path=subfolders in assets folder)
;  globalConfig - global config (globalConfig)
;
; returns asset's full path 
getAssetPath(asset, globalConfig) {
	if (!globalConfig["GUI"].Has("AssetDir") || globalConfig["GUI"]["AssetDir"] = "") {
		ErrorMsg("Cannot get AssetDir when it does not exist in in global.cfg")
		return
	}

	assetPath := globalConfig["GUI"]["AssetDir"] . asset

	if (!FileExist(assetPath)) {
		ErrorMsg("Requested asset [" . asset . "] does not exist")
		return
	}

    return assetPath
}

; gets an thumbnails's path based on the name, or default image-missing
;  asset - asset name / path to get (path=subfolders in assets folder)
;  globalConfig - global config (globalConfig)
;
; returns thumbnail path
getThumbnailPath(asset, globalConfig) {
    assetPath := "data\thumbnails\" . asset . (RegExMatch(asset, "\.\w{2,5}$") ? "" : ".png")
    
	if (!FileExist(assetPath)) {
		return getAssetPath("image-missing.png", globalConfig)
	}

    return assetPath
}

; hides the mouse cursor
;
; returns null
HideMouseCursor() {
    global DEFAULT_MONITOR
    MouseMovePercent(1, 1, DEFAULT_MONITOR)
}