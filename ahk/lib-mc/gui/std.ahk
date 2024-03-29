; cleans up gui config & sets default theming values if not provided in the config
;  guiConfig - GUI config from global.cfg
;
; returns null
parseGUIConfig(guiConfig) {
    global 

    setMonitorInfo(guiConfig)
    
    SIZE := (guiConfig.Has("SizeMultiplier") && guiConfig["SizeMultiplier"] != "")
        ? guiConfig["SizeMultiplier"] : 1
    
    FONT := (guiConfig.Has("Font")) ? guiConfig["Font"] : ""

    FONTCOLOR := (guiConfig.Has("FontColor") && RegExMatch(guiConfig["FontColor"], "U)#[a-fA-F0-9]{6}"))
        ? StrReplace(guiConfig["FontColor"], "#") : "ffffff"

    COLOR1 := (guiConfig.Has("PrimaryColor") && RegExMatch(guiConfig["PrimaryColor"], "U)#[a-fA-F0-9]{6}"))
        ? StrReplace(guiConfig["PrimaryColor"], "#") : "000000"

    COLOR2 := (guiConfig.Has("SecondaryColor") && RegExMatch(guiConfig["SecondaryColor"], "U)#[a-fA-F0-9]{6}"))
        ? StrReplace(guiConfig["SecondaryColor"], "#") : "1a1a1a"

    COLOR3 := (guiConfig.Has("SelectionColor") && RegExMatch(guiConfig["SelectionColor"], "U)#[a-fA-F0-9]{6}"))
        ? StrReplace(guiConfig["SelectionColor"], "#") : "3399ff"
}

; sets global monitor gui variables
;  guiConfig - GUI config from global.cfg
;
; returns null
setMonitorInfo(guiConfig) {
    ; TODO - get selecting a monitor actually working

    global MONITORN
    global MONITORX
    global MONITORY
    global MONITORW
    global MONITORH

    MONITORN := (guiConfig.Has("Monitor") && guiConfig["Monitor"] != "") ? guiConfig.items["Monitor"] : 0
    
    MonitorGet(MONITORN, &ML, &MT, &MR, &MB)

    MONITORX := ML
    MONITORY := MT
    MONITORH := Floor(Abs(MB - MT))
    MONITORW := Floor(Abs(MR - ML))
}

; gets the proper width in pixels based on pixel size of screen
;  width - percentage of the screen width
;  useSize - whether or not to apply the size multipler
;  useDPI - whether or not to apply the screen's dpi
;
; returns proper size in pixels
percentWidth(width, useSize := true, useDPI := false) {
    return MONITORX + (width * MONITORW * ((useSize && width < 1) ? SIZE : 1) * ((useDPI) ? (A_ScreenDPI / 96) : 1))
}

; gets the proper height in pixels based on pixel size of screen
;  height - percentage of the screen height
;  useSize - whether or not to apply the size multipler
;  useDPI - whether or not to apply the screen's dpi
;
; returns proper size in pixels
percentHeight(height, useSize := true, useDPI := false) {
    return MONITORY + (height * MONITORH * ((useSize && height < 1) ? SIZE : 1) * ((useDPI) ? (A_ScreenDPI / 96) : 1))
}

; gets the proper width in pixels based on pixel size of screen
;  width - percentage of the window width
;  wndw - wndw title to get screen pixels from
;
; returns proper size in pixels
percentWidthRelativeWndw(width, wndw) {
    WinGetPos(&X, &Y, &W, &H, wndw)

    return X + (width * W) 
}

; gets the proper height in pixels based on pixel size of screen
;  height - percentage of the window height
;  wndw - wndw title to get screen pixels from
;
; returns proper size in pixels
percentHeightRelativeWndw(height, wndw) {
    WinGetPos(&X, &Y, &W, &H, wndw)
    
    return Y + (height * H)
}

; sets the font of the guiObj using the default options & param options
;  guiObj - gui object to apply font to
;  options - additional options in proper gui option format
;  enableSizing - enable/disable size multiplier
;
; returns null
guiSetFont(guiObj, options := "s15", enableSizing := true) {
    if (Type(guiObj) = "Interface") {
        guiObj := guiObj.guiObj
    }

    optionsMap := Map()
    optionsMap["c"] := FONTCOLOR

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
        optionsMap["s"] := toString(Round((96 / A_ScreenDPI) * Float(optionsMap["s"]) * SIZE * (MONITORH / 1080)))
    }

    ; convert optionMap into properly formatted options string
    optionString := ""
    for key, value in optionsMap {
        optionString .= key . value . A_Space
    }
    optionString := RTrim(optionString, A_Space)

    guiObj.SetFont(optionString, FONT)
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
	if (!globalConfig["General"].Has("AssetDir") || globalConfig["General"]["AssetDir"] = "") {
		ErrorMsg("Cannot get AssetDir when it does not exist in in global.cfg")
		return
	}

	assetPath := globalConfig["General"]["AssetDir"] . asset

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

; gets the cpu load as a float percentage
;
; returns the cpu load
getCpuLoad() {
    static prevKernelUser := 0
    static prevIdle := 0

    kernel := 0
    user := 0
    idle := 0

    DllCall("GetSystemTimes", "Int64P", &idle, "Int64P", &kernel, "Int64P", &user)

    retVal := 100 * (1 - ((idle - prevIdle) / ((kernel + user) - prevKernelUser)))

    prevKernelUser := kernel + user
    prevIdle := idle

	return retVal
}

; gets the ram load as a int percentage
;
; returns the ram load
getRamLoad() {
    status := Buffer(64)
	NumPut("UInt", status.Size, status)
    
	try {
		if !(DllCall("GlobalMemoryStatusEx", "ptr", status.Ptr)) {
			ErrorMsg("Failed to get memory status")
			return 0
		}

		return NumGet(status, 4, "UInt")
	}

    return 0
}

; gets the gpu usage if the user has a nvidia gpu
; this only works when called from main (has the library initialized)
; this only works for 1 gpu (gpu0=256)
;
; returns the gpu usage
getNvidiaLoad() {
    try {
        static mainGPUPtr := 0
        
        if (mainGPUPtr = 0) {
            hwBuffer := Buffer(256, 0)
            
            DllCall(DllCall("nvapi64.dll\nvapi_QueryInterface", "UInt", 0xE5AC921F, "CDecl UPtr"), "Ptr", hwBuffer.Ptr, "UInt*", &temp := 0, "CDecl")
            
            mainGPUPtr := NumGet(hwBuffer, 0, "UInt")
        }
        
        usageBuffer := Buffer(136, 0)
        NumPut("UInt", 136 | 0x10000, usageBuffer)
        
        DllCall(DllCall("nvapi64.dll\nvapi_QueryInterface", "UInt", 0x189A1FDF, "CDecl UPtr"), "Ptr", mainGPUPtr, "Ptr", usageBuffer.Ptr, "CDecl")
        
        return NumGet(usageBuffer, 12, "UInt")
    }
    

	return 0
}

; creates a centered message popup that can be closed with A or B
;  message - message string to show
;  timeout - if > 0 closes window after # of ms
;
; returns null
guiMessage(message, timeout := 0) {
    global 

    guiObj := Gui("+AlwaysOnTop " . GUIOPTIONS, GUIMESSAGETITLE)
    guiObj.BackColor := COLOR1
    guiSetFont(guiObj)
    guiObj.Add("Text", "Center w" . percentWidth(0.3), message)

    guiObj.Show("Center AutoSize NoActivate")

    if (timeout > 0) {
        SetTimer 'MsgCloseTimer', timeout
    }

    MsgCloseTimer() {
        if (WinShown(GUIMESSAGETITLE)) {
            guiObj.Destroy()
        }

        return
    }
}