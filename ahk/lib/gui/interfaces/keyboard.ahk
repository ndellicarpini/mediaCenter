qwerty := Map(
    "default", [
        ["Esc", "``", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "Back"],
        ["Tab", "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]", "\", "Del"],
        ["Caps", "a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'", "Enter"],
        ["Shift", "z", "x", "c", "v", "b", "n", "m", ",", ".", "/", "🡑", "Shift"],
        ["Fn", "Ctrl", "Alt", "", "Alt", "Ctrl", "🡐", "🡓", "🡒"],
    ],
    "shift", [
        [0, "~", "!", "@", "#", "$", "%", "^", "&&", "*", "(", ")", "_", "+", 0],
        [0, "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "{", "}", "|", 0],
        [0, "A", "S", "D", "F", "G", "H", "J", "K", "L", ":", '"', 0],
        [0, "Z", "X", "C", "V", "B", "N", "M", "<", ">", "?", 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
    "func", [
        [0, 0, "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "PgUp", 0],
        [0, 0, 0, 0, 0, 0, "Home", "PgDn", "End"],
    ],
)

class KeyboardInterface extends Interface {
    id := "keyboard"
    title := INTERFACES["keyboard"]["wndw"]

    allowPause := true

    caps  := false
    shift := false
    ctrl  := false
    alt   := false
    func  := false

    currText := ""

    restoreWNDW := -1
    restoreMousePos := []

    layout := Map()

    guiWidth := 0
    guiHeight := 0

    __New() {
        super.__New(GUI_OPTIONS . " +AlwaysOnTop +ToolWindow +E0x08000088")

        this.layout := qwerty

        this.selectColor := COLOR3
        this.guiObj.BackColor := COLOR1

        this.guiWidth := interfaceWidth(0.39)
        this.guiHeight := (this.guiWidth / 21) * 7
        this.SetFont("bold s18")

        this._createKeyboard()

        keySize := Round(this.guiWidth * 0.0588)
        keySpacing := interfaceWidth(0.002) * 2

        xpos := this.control2D.Length
        ypos := this.control2D[xpos].Length

        this.Add("Text", "Center 0x200 vDEATH f(death) BackgroundFF0000 x" 
            . (this.guiWidth - keySize - keySpacing) " y" . (this.guiHeight - keySize - keySpacing)
            . " xpos" . xpos . " ypos" . ypos . " w" . keySize . " h" . keySize, "X")
    }

    _Show() {
        if (WinShown("A")) {
            this.restoreWNDW := WinGetID("A")
        }

        MouseGetPos(&x, &y)
        this.restoreMousePos := [x, y]
        HideMouseCursor()

        super._Show("NoActivate x" . (percentWidth(0.5, false) - (this.guiWidth / 2)) . " y" . percentHeight(0.5, false) . " w" . this.guiWidth . " h" . this.guiHeight)
    }

    _Destroy() {
        super._Destroy()

        if (this.restoreMousePos.Length = 2) {
            MouseMove(this.restoreMousePos[1], this.restoreMousePos[2])
        }

        if (WinShown("ahk_id " this.restoreWNDW)) {
            try WinActivateForeground("ahk_id " this.restoreWNDW)
            Sleep(100)
        }
    }

    _select() {
        key := this.control2D[this.currentX][this.currentY].select

        switch (key) {
            case "death":
                this.Destroy()
            case "Shift":
                this.shift := !this.shift
                this._createKeyboard("update")
            case "Fn":
                this.func := !this.func
                this._createKeyboard("update")
            case "Caps":
                this.caps := !this.caps
                this._createKeyboard("update")
            case "Enter":
                if (this.shift) {
                    this.currText .= "`n"
                }
                else if (this.currText != "") {
                    try {
                        this.Destroy()
                        
                        if (this.currText != "") {
                            Send(this.currText)
                            this.currText := ""
                        }
                    }
                }
            default:
                this.currText .= key

                if (this.shift) {
                    this.shift := false
                    this._createKeyboard("update")
                }

        }
    }

    _back() {
        if (this.currText = "") {
            return
        }

        this.currText := SubStr(this.currText, 1, -1)
    }

    _createKeyboard(mode := "create") {
        buttonFunc := "_" . mode . "KBButton"

        loop this.layout["default"].Length {
            row := A_Index

            colOffset := 0
            loop qwerty["default"][row].Length {
                col := A_Index + colOffset
            
                currKey := qwerty["default"][row][A_Index]
                if (((this.shift && !this.caps) || (!this.shift && this.caps)) && qwerty["shift"][row][A_Index] != 0) {
                    currKey := qwerty["shift"][row][A_Index]
                }
                if (this.func && qwerty["func"][row][A_Index] != 0) {
                    currKey := qwerty["func"][row][A_Index]
                }

                switch (currKey) {
                    case "":
                        this.%buttonFunc%(currKey, COLOR2, col . "-" . col + 5, row, 5.88)
                        colOffset += 5
                    case "Esc":
                        this.%buttonFunc%(currKey, COLOR2, col . "-" . col + 1, row, 1)
                        colOffset += 1
                    case "Back":
                        this.%buttonFunc%(currKey, COLOR2, col . "-" . col + 1, row, 1.48)
                        colOffset += 1
                    case "Tab":
                        this.%buttonFunc%(currKey, COLOR2, col . "-" . col + 1, row, 1.48)
                        colOffset += 1
                    case "Enter":
                        this.%buttonFunc%(currKey, COLOR2, col . "-" . col + 2, row, 2.75)
                        colOffset += 2
                    case "Shift":
                        this.%buttonFunc%(currKey, COLOR2, col . "-" . col + 1, row, 2.325)
                        colOffset += 1
                    case "Caps":
                        this.%buttonFunc%(currKey, COLOR2, col . "-" . col + 1, row, 1.9)
                        colOffset += 1
                    case "Ctrl":
                        this.%buttonFunc%(currKey, COLOR2, col, row, 1.4)
                    default:
                        this.%buttonFunc%(currKey, COLOR2, col, row, 1)
                }
            }
        }

        if (mode = "update") {
            this.guiObj.Redraw()
        }
    }

    _createKBButton(text, color, xpos, ypos, widthScale) {   
        keySize := Round(this.guiWidth * 0.0588)
        keySpacing := interfaceWidth(0.002)

        offset := "x+" . keySpacing
        if (xpos = 1 || Type(xpos) = "String" && StrSplit(xpos, "-")[1] = 1) {
            offset := "x" . (2 * keySpacing) . ((ypos = 1) ? " y" . (2 * keySpacing) : " y+" . keySpacing)
        }
        
        ; add 1 for the close button
        this.Add("Text", "Center 0x200 v" . xpos . ypos . " f(" . text . ") Background" . color . " xpos" . xpos 
            . " ypos" . ypos . " " . offset . " w" . Round(keySize * widthScale) . " h" . keySize, text)
    }

    _updateKBButton(text, color, xpos, ypos, widthScale) {   
        this.guiObj[xpos . ypos].Text := text
    }
}