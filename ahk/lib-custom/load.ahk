loadGUI(args) {
    guiObj := args[1]
    loadText := args[2]
    
    guiObj.BackColor := COLOR1
    
    guiSetFont(guiObj)

    guiObj.Add("ActiveX", "w" . percentWidth(0.1) . " h" . percentWidth(0.1)
        , "mshtml:<img src=" . globalConfig["General"]["AssetDir"] . "loading-compressed.gif />")
    
    guiObj.Add("Text", "Center w" . percentWidth(1), loadText)

    return guiObj
}