global GUIOPTIONS := "-DPIScale -Resize"

global MONITORN := ""
global MONITORH := ""
global MONITORW := ""
global SIZE := ""
global FONT := ""
global FONTCOLOR := ""
global COLOR1 := ""
global COLOR2 := ""

; sets global MONITORH & MONITORW gui variables
;
; returns null
getDisplaySize() {
    global 

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

    MONITORN := (guiConfig.items.Has("Monitor") && guiConfig.items["Monitor"] != "")
        ? guiConfig.items["Monitor"] : 0

    SIZE := (guiConfig.items.Has("SizeMultiplier") && guiConfig.items["SizeMultiplier"] != "")
        ? guiConfig.items["SizeMultiplier"] : 1
    
    FONT := (guiConfig.items.Has("Font")) ? guiConfig.items["FontColor"] : ""

    FONTCOLOR := (guiConfig.items.Has("FontColor") && RegExMatch(guiConfig.items["FontColor"], "U)#[a-fA-F0-9]{6}"))
        ? guiConfig.items["FontColor"] : "#ffffff"

    COLOR1 := (guiConfig.items.Has("PrimaryColor") && RegExMatch(guiConfig.items["PrimaryColor"], "U)#[a-fA-F0-9]{6}"))
        ? guiConfig.items["PrimaryColor"] : "#000000"

    COLOR2 := (guiConfig.items.Has("SecondaryColor") && RegExMatch(guiConfig.items["SecondaryColor"], "U)#[a-fA-F0-9]{6}"))
        ? guiConfig.items["SecondaryColor"] : "#1a1a1a"

    getDisplaySize()
}

guiMessage(guiConfig, message) {
    global 

    guiObj := Gui.New("+AlwaysOnTop " . GUIOPTIONS)
}