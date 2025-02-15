; cleans up gui config & sets default theming values if not provided in the config
;
; returns null
setGUIConstants() {
    global globalConfig
    global SIZE   
    global FONT
    global FONT_COLOR
    global COLOR1
    global COLOR2
    global COLOR3 

    setMonitorInfo()
    setInterfaceOverrides()

    if (!globalConfig.Has("GUI")) {
        return
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

; gets monitor info for specified monitor
;  monitorNum - monitor to get info for
;
; returns array of [x, y, w, h]
getMonitorInfo(monitorNum) {
    MonitorGet(monitorNum, &ML, &MT, &MR, &MB)
    return [ML, MT, Floor(Abs(MR - ML)), Floor(Abs(MB - MT))]
}

; sets global monitor gui variables
;
; returns null
setMonitorInfo() {
    ; TODO - get selecting a monitor actually working

    global globalConfig
    global MONITOR_N
    global MONITOR_X
    global MONITOR_Y
    global MONITOR_W
    global MONITOR_H

    if (!globalConfig.Has("GUI")) {
        return
    }

    MONITOR_N := (globalConfig["GUI"].Has("MonitorNum") && globalConfig["GUI"]["MonitorNum"] != "") ? globalConfig["GUI"]["MonitorNum"] : 0
    if (MONITOR_N <= 0) {
        MONITOR_N := MonitorGetPrimary()
    }

    info := getMonitorInfo(MONITOR_N)
    MONITOR_X := info[1]
    MONITOR_Y := info[2]
    MONITOR_W := info[3]
    MONITOR_H := info[4]
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
;  width - percentage of the screen width
;  useSize - whether or not to apply the size multipler
;  useDPI - whether or not to apply the screen's dpi
;
; returns proper size in pixels
percentWidth(width, useSize := true, useDPI := false) {
    retVal := (width * MONITOR_W * ((useSize && width < 1) ? SIZE : 1) * ((useDPI) ? (A_ScreenDPI / 96) : 1))
    ; check that new width isn't greater than the screen
    if (retVal > MONITOR_W) {
        return MONITOR_W
    }

    return retVal
}

; gets the proper height in pixels based on pixel size of screen
;  height - percentage of the screen height
;  useSize - whether or not to apply the size multipler
;  useDPI - whether or not to apply the screen's dpi
;
; returns proper size in pixels
percentHeight(height, useSize := true, useDPI := false) {
    retVal := (height * MONITOR_H * ((useSize && height < 1) ? SIZE : 1) * ((useDPI) ? (A_ScreenDPI / 96) : 1))
    ; check that new height isn't greater than the screen
    if (retVal > MONITOR_H) {
        return MONITOR_H
    }

    return retVal
}

; get the proper width of an interface based on the pixel size of screen
; keeps the aspect ratio relative to the original design aspect ratio of 16/9
;  width - percentage of the screen width
;
; returns proper size in pixels
interfaceWidth(width) {
    aspectRatioMult := (16/9) / (MONITOR_W / MONITOR_H)
    retVal := width * aspectRatioMult * MONITOR_W * SIZE
    
    return Min(retVal, MONITOR_W)
}

; get the proper height of an interface based on the pixel size of screen
; keeps the aspect ratio relative to the original design aspect ratio of 16/9
;  height - percentage of the screen width
;
; returns proper size in pixels
interfaceHeight(height) {
    ; aspectRatioMult := (16/9) / (MONITOR_W / MONITOR_H)
    aspectRatioMult := 1
    retVal := height * (1 / aspectRatioMult) * MONITOR_H * SIZE
    
    return Min(retVal, MONITOR_H)
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

; sets the font of the guiObj using the default options & param options
;  guiObj - gui object to apply font to
;  options - additional options in proper gui option format
;  enableSizing - enable/disable size multiplier
;
; returns null
guiSetFont(guiObj, options := "s15", enableSizing := true) {
    optionsMap := Map()
    optionsMap["c"] := FONT_COLOR

    ; set options from parameter
    if (options != "") {
        if (Type(options) != "String") {
            ErrorMsg("guiSetFont options must be a string")
            return
        }

        optionsArr := StrSplit(options, A_Space)
        for item in optionsArr {
            optionsMap[SubStr(item, 1, 1)] := SubStr(item, 2)
        }
    }

    ; update the font size if the size multiplier is enabled
    ; the font size is scaled based on the 96 / screen's dpi (96 = default windows dpi)
    ; its also scaled by the monitor width compared to 1080p 
    if (enableSizing) {
        optionsMap["s"] := toString(Round((96 / A_ScreenDPI) * Float(optionsMap["s"]) * SIZE * (MONITOR_H / 1080)))
    }

    ; convert optionMap into properly formatted options string
    optionString := ""
    for key, value in optionsMap {
        optionString .= key . value . A_Space
    }

    optionString := RTrim(optionString, A_Space)
    if (FONT != "") {
        guiObj.SetFont(optionString, FONT)
    }
    else {
        guiObj.SetFont(optionString)
    }
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
    MouseMovePercent(1, 1, MONITOR_N)
}