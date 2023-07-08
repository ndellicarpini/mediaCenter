class SpinLoadScreen extends LoadScreenInterface {
    __New(text) {
        global globalConfig

        ; disgusting way to get to the granddaddy class
        (SpinLoadScreen.Base.Base.Prototype.__New)(this, INTERFACES["loadscreen"]["wndw"], GUI_OPTIONS)

        this.guiObj.BackColor := COLOR1
        this.SetFont("s26")
        this.Add("Text", "vLoadText Center x0 y" . percentHeight(0.92, false) " w" . percentWidth(1), text)

        imgSize := percentWidth(0.04)
        imgHTML := (
            "<html>"
                "<body style='background-color: transparent' style='overflow:hidden' leftmargin='0' topmargin='0'>"
                    "<img src='" getAssetPath("loading.gif", globalConfig) "' width=" . imgSize . " height=" . imgSize . " border=0 padding=0>"
                "</body>"
            "</html>"
        )
        ; imgHTML := (
        ;     "<html>"
        ;         "<head>"
        ;             "<style>"
        ;                 "body {"
        ;                     "background-color: transparent;"
        ;                     "overflow: hidden;"
        ;                     "margin-left: 0;"
        ;                     "margin-top: 0;"
        ;                 "}"
        ;                 "img {"
        ;                     "padding: 0;"
        ;                     "border: 0;"
        ;                     "background-color: #ff0000;" 
        ;                     "animation-delay: 0s;"
        ;                     "animation-duration: 2s;"
        ;                     "animation-iteration-count: 2000;"
        ;                     "animation-name: rotation;"
        ;                 "}"
        ;                 "@keyframes rotation {"
        ;                     "from {"
        ;                         "transform: rotate(0deg);"
        ;                     "}"
        ;                     "to {"
        ;                         "transform: rotate(359deg);"
        ;                     "}"
        ;                 "}"
        ;             "</style>"
        ;         "</head>"
        ;         "<body>"
        ;             "<img src='" . getAssetPath("loading-spinner.png", globalConfig) . "' width=" . imgSize . " height=" . imgSize . "/>"
        ;         "</body>"
        ;     "</html>"
        ; )

        IMG := this.Add("ActiveX", "w" . imgSize . " h" . imgSize . " x" . percentWidth(0.5, false) - (imgSize / 2) . " yp-" . (imgSize + percentHeight(0.015)), "Shell.Explorer").Value
        IMG.Navigate("about:blank")
        IMG.document.write(imgHTML)
    }
}