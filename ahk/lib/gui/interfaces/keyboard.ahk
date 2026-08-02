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

    textColor  := FONT_COLOR
    capsColor  := FONT_COLOR
    shiftColor := FONT_COLOR
    ctrlColor  := "FF0000"
    altColor   := "0000FF"
    funcColor  := FONT_COLOR

    ; nice hack loser
    _shiftFromKeyboard := false
    _ctrlFromKeyboard  := false
    _altFromKeyboard   := false
    _funcFromKeyboard  := false

    currTextArr := []

    restoreWNDW := -1
    restoreMousePos := []

    layout := Map()

    guiWidth := 0
    guiHeight := 0

    _maxCol := 0
    _keySize := 0
    _keySpacing := 0

    __New() {
        super.__New(GUI_OPTIONS . " +AlwaysOnTop +Overlay000000 +ToolWindow +E0x08000088")

        this.layout := qwerty

        this.selectColor := COLOR3
        this.guiObj.BackColor := COLOR1

        this.guiWidth := this._calcPercentWidth(0.38)
        this.guiHeight := (this.guiWidth / 21) * 8.78

        this._keySize := Round(this.guiWidth * 0.0588)
        this._keySpacing := this._calcPercentWidth(0.002)

        this._createKeyboard()

        ypos := this.layout["default"].Length
        xpos := this._maxCol + 1

        this.SetFont("bold s18 c" . this.textColor)
        this.Add("Text", "Center 0x200 vDEATH f(death) BackgroundFF0000 x" 
            . (this.guiWidth - this._keySize - (2.25 * this._keySpacing)) 
            . " y" . (this.guiHeight - this._keySize - (2 * this._keySpacing))
            . " xpos" . xpos . " ypos" . ypos . " w" . this._keySize . " h" . this._keySize, "X")
    }

    _Show() {
        if (WinShown("A")) {
            this.restoreWNDW := WinGetID("A")
        }

        MouseGetPos(&x, &y)
        this.restoreMousePos := [x, y]
        HideMouseCursor()

        super._Show("NoActivate x" . (this._calcPercentWidth(0.5, false) - (this.guiWidth / 2)) 
                    . " y" . this._calcPercentHeight(0.4, false) . " w" . this.guiWidth . " h" . this.guiHeight)
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
        this.keyboard(key)

        keyLower := StrLower(key)
        if (keyLower = "shift") {
            this._shiftFromKeyboard := !this._shiftFromKeyboard
        } 
        else if (keyLower = "ctrl") {
            this._ctrlFromKeyboard := !this._ctrlFromKeyboard
        } 
        else if (keyLower = "alt") {
            this._altFromKeyboard := !this._altFromKeyboard
        } 
        else if (keyLower = "func") {
            this._funcFromKeyboard := !this._funcFromKeyboard
        }
    }

    _back() {
        if (this.currTextArr.Length = 0) {
            return
        }

        this.keyboard("back")
        this._buildTextDisplay()
    }

    _createKeyboard(mode := "create") {        
        this._buildTextDisplay()

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

                switch (row . "-" . A_Index) {
                    ; Space
                    case "5-4":
                        this.%buttonFunc%(currKey, COLOR2, col . "-" . col + 5, row, 5.88)
                        colOffset += 5
                    ; Esc
                    case "1-1":
                        this.%buttonFunc%(currKey, COLOR2, col . "-" . col + 1, row, 1)
                        colOffset += 1
                    ; Back
                    case "1-15":
                        this.%buttonFunc%(currKey, COLOR2, col . "-" . col + 1, row, 1.48)
                        colOffset += 1
                    ;Tab
                    case "2-1":
                        this.%buttonFunc%(currKey, COLOR2, col . "-" . col + 1, row, 1.48)
                        colOffset += 1
                    ; Enter
                    case "3-13":
                        this.%buttonFunc%(currKey, COLOR2, col . "-" . col + 2, row, 2.75)
                        colOffset += 2
                    ; LShift
                    case "4-1":
                        this.%buttonFunc%(currKey, COLOR2, col . "-" . col + 1, row, 2.325)
                        colOffset += 1
                    ; RShift
                    case "4-13":
                        this.%buttonFunc%(currKey, COLOR2, col . "-" . col + 1, row, 2.325)
                        colOffset += 1
                    ; Caps
                    case "3-1":
                        this.%buttonFunc%(currKey, COLOR2, col . "-" . col + 1, row, 1.9)
                        colOffset += 1
                    ; LCtrl
                    case "5-2":
                        this.%buttonFunc%(currKey, COLOR2, col, row, 1.4)
                    ; RCtrl
                    case "5-6":
                        this.%buttonFunc%(currKey, COLOR2, col, row, 1.4)
                    default:
                        this.%buttonFunc%(currKey, COLOR2, col, row, 1)
                }

                if (col > this._maxCol) {
                    this._maxCol := col
                }
            }
        }

        if (mode = "update") {
            this.guiObj.Redraw()
        }
    }

    _createKBButton(text, color, xpos, ypos, widthScale) {
        offset := "x+" . this._keySpacing
        if (xpos = 1 || Type(xpos) = "String" && StrSplit(xpos, "-")[1] = 1) {
            offset := "x" . (2 * this._keySpacing) . " y+" . ((ypos = 1 ? 2 : 1) * this._keySpacing)
        }

        width := Round(this._keySize * widthScale)
        
        textLower := StrLower(text)
        if (textLower = "home" || textLower = "end" || textLower = "pgup" || textLower = "pgdn") {
            this.SetFont("bold s11 c" . this.textColor)
        }
        else {
            this.SetFont("bold s18 c" . this.textColor)
        }

        this.Add("Text", "Center 0x200 v" . xpos . ypos . " f(" . text . ") Background" . color . " xpos" . xpos 
            . " ypos" . ypos . " " . offset . " w" . width . " h" . this._keySize, text)

        if (textLower = "caps") {
            this._addToggle(this.caps, xpos, ypos, width, this.capsColor, this._keySize)
        }
        else if (textLower = "shift") {
            this._addToggle(this.shift, xpos, ypos, width, this.shiftColor, this._keySize)
        }
        else if (textLower = "ctrl") {
            this._addToggle(this.ctrl, xpos, ypos, width, this.ctrlColor, this._keySize)
        }
        else if (textLower = "alt") {
            this._addToggle(this.alt, xpos, ypos, width, this.altColor, this._keySize)
        }
        else if (textLower = "fn") {
            this._addToggle(this.func, xpos, ypos, width, this.funcColor, this._keySize)
        }
    }

    _updateKBButton(text, color, xpos, ypos, widthScale) {   
        currTextLower := StrLower(this.guiObj[xpos . ypos].Text)
        this.guiObj[xpos . ypos].Text := text
        textLower := StrLower(text)

        if (textLower = "home" || textLower = "end" || textLower = "pgup" || textLower = "pgdn") {
            this.guiObj[xpos . ypos].SetFont("s" . this._calcFontSize(11))
        }
        else if (currTextLower = "home" || currTextLower = "end" || currTextLower = "pgup" || currTextLower = "pgdn") {
            this.guiObj[xpos . ypos].SetFont("s" . this._calcFontSize(18))
        }
        else if (textLower = "caps") {
            this._updateToggle(this.caps, xpos, ypos, this.capsColor)
        }
        else if (textLower = "shift") {
            this._updateToggle(this.shift, xpos, ypos, this.shiftColor)
        }
        else if (textLower = "ctrl") {
            this._updateToggle(this.ctrl, xpos, ypos, this.ctrlColor)
        }
        else if (textLower = "alt") {
            this._updateToggle(this.alt, xpos, ypos, this.altColor)
        }
        else if (textLower = "fn") {
            this._updateToggle(this.func, xpos, ypos, this.funcColor)
        }
    }

    _addToggle(state, xpos, ypos, width, color, keySize) {
        this.SetFont("bold s8 c" . (state ? color : COLOR1))
        this.Add("Text", "Right BackgroundTrans v" . xpos . ypos . "Toggle x+-" . width . " y+-" . keySize
            . " w" . width . " h" . keySize, Chr(0x25CF) . " ")
    }

    _updateToggle(state, xpos, ypos, color) {
        this.guiObj[xpos . ypos . "Toggle"].SetFont("c" . (state ? color : COLOR1))
    }

    _buildTextDisplay() {
        
        this.Add("Text", "Left 0x200 vTEXT Background" . COLOR2 . " x" . (2 * this._keySpacing) . " y" . (2 * this._keySpacing)
            . " w" . (this.guiWidth - (4 * this._keySpacing)) . " h" . (this._keySize * 1.25), " " . this.currText)

            this.SetFont("bold s18 c" . this.textColor)
            this.Add("Text", "Left 0x200 vTEXT Background" . COLOR2 . " x" . (2 * this._keySpacing) . " y" . (2 * this._keySpacing)
                . " w" . (this.guiWidth - (4 * this._keySpacing)) . " h" . (this._keySize * 1.25), " " . this.currText)
    }

    ; function used to actually add a keystroke to the state
    ; can be used with hotkeys
    ; key - key to send
    ;
    ; returns null
    keyboard(key := "") {
        keyLower := StrLower(key)
        switch (keyLower) {
            case "death":
                this.Destroy()
                return
            ; TODO - MOVE THIS LOGIC TO A SEND KEY HANDLER OR SOMETHING
            case "back":
                this.shift := !this.shift
            case "enter":
                ; CHECK MODE INSTEAD
                if (this.shift) {
                    this.currTextArr.Push("enter")
                }
                else {
                    this.sendText()
                }
                return
            case "shift":
                this.shift := !this.shift
            case "ctrl":
                this.ctrl := !this.ctrl
            case "alt":
                this.alt := !this.alt
            case "fn":
                this.func := !this.func
            case "caps":
                this.caps := !this.caps
        }

        if (keyLower = "" || keyLower = "space") {
            this.currTextArr.Push(" ")
        }
        else {
            this.currTextArr.Push(keyLower)
        }

        ; disable modifier if enabled from the keyboard rather than hotkey
        if (this.shift && this._shiftFromKeyboard) {
            this.shift := false
            this._shiftFromKeyboard := false
        }
        if (this.ctrl && this._ctrlFromKeyboard) {
            this.ctrl := false
            this._ctrlFromKeyboard := false
        }
        if (this.alt && this._altFromKeyboard) {
            this.alt := false
            this._altFromKeyboard := false
        }
        if (this.func && this._funcFromKeyboard) {
            this.func := false
            this._funcFromKeyboard := false
        }

        this._createKeyboard("update")
    }

    sendText() {
        try {
            this.Destroy()
            
            ; TODO - probably context dependent Send right?
            ; sending inputs to guis
            ; sending inputs to programs
            ; sending inputs generic
            MsgBox('ooo la la')
        }
    }
}