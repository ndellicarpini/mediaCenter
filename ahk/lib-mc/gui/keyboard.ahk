global KBCAPSED := false
global KBSHIFTED := false
global KBCTRLED  := false
global KBALTED   := false
global KBFUNCED  := false

qwerty := {
    default: [
        ["Esc", "``", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "Back"],
        ["Tab", "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]", "\", "Del"],
        ["Caps", "a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'", "Enter"],
        ["Shift", "z", "x", "c", "v", "b", "n", "m", ",", ".", "/", "^", "Shift"],
        ["Fn", "Ctrl", "Alt", "", "Alt", "Ctrl", "<", "V", ">"],
    ],
    shift: [
        [0, "~", "!", "@", "#", "$", "%", "^", "&&", "*", "(", ")", "_", "+", 0],
        [0, "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "{", "}", "|", 0],
        [0, "A", "S", "D", "F", "G", "H", "J", "K", "L", ":", '"', 0],
        [0, "Z", "X", "C", "V", "B", "N", "M", "<", ">", "?", 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0],
    ],
    function: [
        [0, 0, "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, "PgUp", 0],
        [0, 0, 0, 0, 0, 0, "Home", "PgDn", "End"],
    ],
}

guiKeyboard() {
    global globalGuis
    global globalRunning

    currProgram := getStatusParam("currProgram")

    kbHotkeys := Map(
        "[HOLD]RSX>0.4", "moveKeyboard 1 0",
        "[HOLD]RSX<-0.4", "moveKeyboard -1 0",
        "[HOLD]RSY>0.4", "moveKeyboard 0 -1",
        "[HOLD]RSY<-0.4", "moveKeyboard 0 1",
    )

    createInterface(GUIKEYBOARDTITLE, GUIOPTIONS . " +AlwaysOnTop",, kbHotkeys, true,, false,, "destroyKeyboard")
    kbInt := globalGuis[GUIKEYBOARDTITLE]

    if (getStatusParam("kbmmode")) {
        kbInt.hotkeys := addHotkeys(kbmmodeHotkeys(), kbInt.hotkeys)
        kbInt.mouse := kbmmodeMouse()
    }
    else if (!getStatusParam("desktopmode") && currProgram != "" && globalRunning.Has(currProgram)) {
        currHotkeys := kbInt.hotkeys
        currHotkeys := addHotkeys(globalRunning[currProgram].hotkeys, currHotkeys)

        kbInt.hotkeys := currHotkeys
        kbInt.mouse := globalRunning[currProgram].mouse
    }

    kbInt.selectColor := COLOR3

    kbInt.guiObj.BackColor := COLOR1

    guiWidth := percentWidth(0.39)
    guiHeight := (guiWidth / 21) * 7

    keySize  := Round(guiWidth * 0.0588)

    guiSetFont(kbInt, "bold s18")

    loop qwerty.default.Length {
        row := A_Index

        colOffset := 0
        loop qwerty.default[row].Length {
            col := A_Index + colOffset
            
            currKey := qwerty.default[row][A_Index]
            switch (currKey) {
                case "":
                    guiKeyboardButton(kbInt, currKey, COLOR2, col . "-" . col + 5, row, (keySize * 5.88), keySize)
                    colOffset += 5
                case "Back":
                    guiKeyboardButton(kbInt, currKey, COLOR2, col . "-" . col + 1, row, (keySize * 1.48), keySize)
                    colOffset += 1
                case "Tab":
                    guiKeyboardButton(kbInt, currKey, COLOR2, col . "-" . col + 1, row, (keySize * 1.48), keySize)
                    colOffset += 1
                case "Enter":
                    guiKeyboardButton(kbInt, currKey, COLOR2, col . "-" . col + 2, row, (keySize * 2.75), keySize)
                    colOffset += 2
                case "Shift":
                    guiKeyboardButton(kbInt, currKey, COLOR2, col . "-" . col + 1, row, (keySize * 2.325), keySize)
                    colOffset += 1
                case "Caps":
                    guiKeyboardButton(kbInt, currKey, COLOR2, col . "-" . col + 1, row, (keySize * 1.9), keySize)
                    colOffset += 1
                case "Ctrl":
                    guiKeyboardButton(kbInt, currKey, COLOR2, col, row, (keySize * 1.4), keySize)
                default:
                    guiKeyboardButton(kbInt, currKey, COLOR2, col, row, keySize, keySize)
            }
        }
    }

    Hotkey("Alt", kbAltDown)
    Hotkey("Alt up", kbAltUp)
    Hotkey("Ctrl", kbCtrlDown)
    Hotkey("Ctrl up", kbCtrlUp)
    Hotkey("Shift", kbShiftDown)
    Hotkey("Shift up", kbShiftUp)

    kbInt.Show("NoActivate x" . (percentWidth(0.5, false) - (guiWidth / 2)) . " y" . percentHeight(0.5, false) . " w" . guiWidth . " h" . guiHeight)
    WinSetTransparent(230, GUIKEYBOARDTITLE)
}

guiKeyboardButton(kbInt, text, color, xpos, ypos, w, h) {
    keySpacing := percentWidth(0.002)

    offset := "x+" . keySpacing
    if (xpos = 1 || Type(xpos) = "String" && StrSplit(xpos, "-")[1] = 1) {
        offset := "x" . (2 * keySpacing) . ((ypos = 1) ? " y" . (2 * keySpacing) : " y+" . keySpacing)
    }

    kbInt.Add("Text", "Center 0x200 v" . xpos . ypos . " f(sendKeyboardButton " . text . ") Background" . color . " xpos" . xpos . " ypos" . ypos
        . " " . offset . " w" . w . " h" . h, text)
}

sendKeyboardButton(button := "") {
    global KBCAPSED
    global KBSHIFTED
    global KBCTRLED 
    global KBALTED  
    global KBFUNCED

    switch (button) {
        case "Esc":
            Send("{Escape}")
        case "Del":
            Send("{Delete}")
        case "^":
            Send("{Up}")
        case "V":
            Send("{Down}")
        case "<":
            Send("{Left}")
        case ">":
            Send("{Right}")
        case "Back":
            Send("{Backspace}")
        case "Tab":
            Send("{Tab}")
        case "Enter":
            Send("{Enter}")
        case "Ctrl":
                if (!KBCTRLED) {
                KBCTRLED := true
                Send("{Ctrl down}")
            }
            else { 
                KBCTRLED := false
                Send("{Ctrl up}")
            }
        case "Alt":
            if (!KBALTED) {
                KBALTED := true
                Send("{Alt down}")
            }
            else { 
                KBALTED := false
                Send("{Alt up}")
            }
        case "Caps":
            if (KBSHIFTED) {
                KBSHIFTED := false
            }

            if (!KBCAPSED) {
                KBCAPSED := true
                Send("{Shift down}")
            }
            else { 
                KBCAPSED := false
                Send("{Shift up}")
            }
        case "Shift":
            if (KBCAPSED) {
                KBCAPSED := false
            }
            
            if (!KBSHIFTED) {
                KBSHIFTED := true
                Send("{Shift down}")
            }
            else { 
                KBSHIFTED := false
                Send("{Shift up}")
            }
        case "Fn":
            Send("TODO")
        case "":
            Send(" ")
        default:
            Send(button)
    }
}

kbAltDown(_) {

}

kbAltUp(_) {

}

kbCtrlDown(_) {

}

kbCtrlUp(_) {

}

kbShiftDown(_) {
    MsgBox("hi")
}

kbShiftUp(_) {
    MsgBox("bye")
}

moveKeyboard(xDir, yDir) {
    WinGetPos(&x, &y, &w, &h, GUIKEYBOARDTITLE)
    newX := x
    newY := y

    if (xDir != 0) {
        newX := x + (xDir * percentWidth(0.03))
        if (newX < 0) {
            newX := 0
        }
        else if (newX + w > MONITORW) {
            newX := MONITORW - w
        }
    }

    if (yDir != 0) {
        newY := y + (yDir * percentWidth(0.03))
        if (newY < 0) {
            newY := 0
        }
        else if (newY + h > MONITORH) {
            newY := MONITORH - h
        }
    }

    WinMove(newX, newY,,, GUIKEYBOARDTITLE)
}

destroyKeyboard() {
    global globalGuis

    global KBALTED
    global KBCTRLED
    global KBSHIFTED

    if (getGUI(GUIKEYBOARDTITLE)) {
        Hotkey("Alt", "Off")
        Hotkey("Alt up", "Off")
        Hotkey("Ctrl", "Off")
        Hotkey("Ctrl up", "Off")
        Hotkey("Shift", "Off")
        Hotkey("Shift up", "Off")

        if (KBALTED) {
            Send("{Alt up}")
            KBALTED := false
        }
        if (KBCTRLED) {
            Send("{Ctrl up}")
            KBCTRLED := false
        }
        if (KBSHIFTED) {
            Send("{Shift up}")
            KBSHIFTED := false
        }
        if (GetKeyState("CapsLock", "T")) {
            SetCapsLockState "Off"
        }

        globalGuis[GUIKEYBOARDTITLE].guiObj.Destroy()
    }
}