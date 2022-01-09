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

; sets global monitor gui variables
;  guiConfig - GUI config from global.cfg
;
; returns null
setMonitorInfo(guiConfig) {
    global 

    MONITORN := (guiConfig.items.Has("Monitor") && guiConfig.items["Monitor"] != "")
    ? guiConfig.items["Monitor"] : 0
    
    MonitorGet(MONITORN, ML, MT, MR, MB)

    MONITORH := Floor(Abs(MB - MT))
    MONITORW := Floor(Abs(MR - ML))
}

; cleans up gui config & sets default theming values if not provided in the config
;  guiConfig - GUI config from global.cfg
;
; returns null
parseGUIConfig(guiConfig) {
    global 

    setMonitorInfo(guiConfig)
    
    SIZE := (guiConfig.items.Has("SizeMultiplier") && guiConfig.items["SizeMultiplier"] != "")
        ? guiConfig.items["SizeMultiplier"] : 1
    
    FONT := (guiConfig.items.Has("Font")) ? guiConfig.items["Font"] : ""

    FONTCOLOR := (guiConfig.items.Has("FontColor") && RegExMatch(guiConfig.items["FontColor"], "U)#[a-fA-F0-9]{6}"))
        ? StrReplace(guiConfig.items["FontColor"], "#") : "ffffff"

    COLOR1 := (guiConfig.items.Has("PrimaryColor") && RegExMatch(guiConfig.items["PrimaryColor"], "U)#[a-fA-F0-9]{6}"))
        ? StrReplace(guiConfig.items["PrimaryColor"], "#") : "000000"

    COLOR2 := (guiConfig.items.Has("SecondaryColor") && RegExMatch(guiConfig.items["SecondaryColor"], "U)#[a-fA-F0-9]{6}"))
        ? StrReplace(guiConfig.items["SecondaryColor"], "#") : "1a1a1a"
}

; gets a gui object with the specified wintitle
;  title - title of gui window
;
; returns gui object from title
getGUI(title) {
    hwnd := WinGetID(title)

    return GuiFromHwnd(hwnd)
}

; gets the proper width in pixels based on pixel size of screen
;  width - percentage of the screen width
;  useSize - whether or not to apply the size multipler
;
; returns proper size in pixels
guiWidth(width, useSize := true) {
    return width * MONITORW * ((useSize) ? SIZE : 1)
}

; gets the proper height in pixels based on pixel size of screen
;  height - percentage of the screen height
;  useSize - whether or not to apply the size multipler
;
; returns proper size in pixels
guiHeight(height, useSize := true) {
    return height * MONITORH * ((useSize) ? SIZE : 1)
}

; sets the font of the guiObj using the default options & param options
;  guiObj - gui object to apply font to
;  options - additional options in proper gui option format
;
; returns null
guiSetFont(guiObj, options := "") {
    optionsMap := Map()
    optionsMap["c"] := FONTCOLOR
    optionsMap["s"] := toString((20 * SIZE))

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
    guiObj.Add("Text", "w" . guiWidth(0.3), message)

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