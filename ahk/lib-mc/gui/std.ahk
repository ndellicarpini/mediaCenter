global GUIOPTIONS := "-DPIScale -Resize -Caption"

global MONITORN := ""
global MONITORH := ""
global MONITORW := ""
global SIZE := ""
global FONT := ""
global FONTCOLOR := ""
global COLOR1 := ""
global COLOR2 := ""

global GUIMESSAGETITLE := "AHKGUIMESSAGE"
global GUILOADTITLE := "AHKGUILOAD"
global GUIPAUSETITLE := "AHKGUIPAUSE"

; sets global monitor gui variables
;  guiConfig - GUI config from global.cfg
;
; returns null
setMonitorInfo(guiConfig) {
    ; TODO - get selecting a monitor actually working

    global 

    MONITORN := (guiConfig.Has("Monitor") && guiConfig["Monitor"] != "")
    ? guiConfig.items["Monitor"] : 0
    
    MonitorGet(MONITORN, ML, MT, MR, MB)

    MONITORH := Floor(Abs(MB - MT))
    MONITORW := Floor(Abs(MR - ML))
}

; gets the proper width in pixels based on pixel size of screen
;  width - percentage of the screen width
;  useSize - whether or not to apply the size multipler
;
; returns proper size in pixels
percentWidth(width, useSize := true) {
    return width * MONITORW * ((useSize && width < 1) ? SIZE : 1)
}

; gets the proper height in pixels based on pixel size of screen
;  height - percentage of the screen height
;  useSize - whether or not to apply the size multipler
;
; returns proper size in pixels
percentHeight(height, useSize := true) {
    return height * MONITORH * ((useSize && height < 1) ? SIZE : 1)
}

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
}

; gets a gui object with the specified wintitle
;  title - title of gui window
;
; returns gui object from title
getGUI(title) {
    try {
        hwnd := WinGetID(title)

        return GuiFromHwnd(hwnd)
    }
}

; sets the font of the guiObj using the default options & param options
;  guiObj - gui object to apply font to
;  options - additional options in proper gui option format
;  enableSizing - enable/disable size multiplier
;
; returns null
guiSetFont(guiObj, options := "s20", enableSizing := true) {
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
    if (enableSizing) {
        optionsMap["s"] := toString(Round((96 / A_ScreenDPI) * Integer(optionsMap["s"]) * SIZE))
    }

    ; convert optionMap into properly formatted options string
    optionString := ""
    for key, value in optionsMap {
        optionString .= key . value . A_Space
    }
    optionString := RTrim(optionString, A_Space)

    guiObj.SetFont(optionString, FONT)
}

; creates a centered message popup that can be closed with A or B]
;  message - message string to show
;  timeout - if > 0 closes window after # of ms
;
; returns null
guiMessage(message, timeout := 0) {
    global 

    guiObj := Gui.New("+AlwaysOnTop " . GUIOPTIONS, GUIMESSAGETITLE)
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