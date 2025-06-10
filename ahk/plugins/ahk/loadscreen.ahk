class SpinLoadScreen extends LoadScreenInterface {
    __New(text) {
        global globalConfig

        ; disgusting way to get to the granddaddy class
        (SpinLoadScreen.Base.Base.Prototype.__New)(this, GUI_OPTIONS)

        this.guiObj.BackColor := COLOR1
        this.SetFont("s26")
        this.Add("Text", "vLoadText Center x0 y" . this._calcPercentHeight(0.92, false) " w" . this._calcPercentWidth(1), text)

        imgSize := this._calcPercentWidth(0.04)
        imgHTML := (
            "<html>"
                "<body style='width: 100%; height: 100%; overflow: hidden; margin: 0; background-color: #" . COLOR1 . ";'>"
                    "<img style='width: 100%; height: 100%; object-fit: contain;' src='" . getAssetPath("loading.gif", globalConfig) . "'/>"
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

        IMG := this.Add("ActiveX", "w" . imgSize . " h" . imgSize . " x" . this._calcPercentWidth(0.5, false, false) - (imgSize / 2) 
            . " yp-" . (imgSize + this._calcPercentHeight(0.015)), "Shell.Explorer").Value
        IMG.Navigate("about:blank")
        IMG.document.write(imgHTML)
    }
}