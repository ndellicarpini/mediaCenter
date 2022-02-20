; the load gui function takes very specific parameters, and should always return a GUI object
; this is just used to customize the load screen gui if the user wants to
;  args[0] - GUI object to append new styling to
;
; returns GUI obj with new load screen styling
loadGUI(args) {
    guiObj := args[1]
    
    guiObj.BackColor := COLOR1
    
    guiSetFont(guiObj, "s35")

    imgSize := percentWidth(0.04)
    
    guiObj.Add("Text", "vLoadText Center x0 y" . percentHeight(0.92, false) " w" . percentWidth(1), getStatusParam("loadText"))

    imgHTML := (
        "<html>"
            "<body style='background-color: transparent' style='overflow:hidden' leftmargin='0' topmargin='0'>"
                "<img src='" getAssetPath("loading.gif") "' width=" . imgSize . " height=" . imgSize . " border=0 padding=0>"
            "</body>"
        "</html>"
    )

    IMG := guiObj.Add("ActiveX", "w" . imgSize . " h" . imgSize . " x" . percentWidth(0.5, false) - (imgSize / 2) . " yp-" . (imgSize + percentHeight(0.015)), "Shell.Explorer").Value
    IMG.Navigate("about:blank")
    IMG.document.write(imgHTML)

    return guiObj
}