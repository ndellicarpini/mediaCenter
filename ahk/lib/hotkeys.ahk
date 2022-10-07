; gets the default hotkeys & formats them into the proper hotkey map
;  config - config taken from main
;
; returns map of default hotkeys
defaultHotkeys(config) {
    newHotkeys := Map()

    buttonTime := (config["Hotkeys"].Has("ButtonTime")) ? config["Hotkeys"]["ButtonTime"] : 70

    for key in config["Hotkeys"] {
        if (key = "ButtonTime") {
            continue
        }

        ; only add pause hotkey if pausing is enabled
        if (StrLower(key) = "pausemenu" && config["GUI"].Has("EnablePauseMenu") && config["GUI"]["EnablePauseMenu"]) {  
            newHotkeys[config["Hotkeys"][key]] := Map("down", key, "time", buttonTime)
        }
        else if (StrLower(key) = "exitprogram") {
            newHotkeys[config["Hotkeys"][key]] := Map("down", key, "time", buttonTime * 1.5)
        }
        else {
            newHotkeys[config["Hotkeys"][key]] := Map("down", key, "time", buttonTime)
        }
    }

    return newHotkeys 
}

addHotkeys(currHotkeys, newHotkeys) {
    oldHotkeys := ObjDeepClone(currHotkeys)

    for key, value in newHotkeys {
        currModifier := checkHotkeyModifier(key)
        currKey := (currModifier != "") ? StrReplace(key, currModifier, "") : key

        if (InStr(currKey, ">")) {
            currKey := StrSplit(currKey, ">")[1] . ">"
        }
        else if (InStr(currKey, "<")) {
            currKey := StrSplit(currKey, "<")[1] . "<"
        }

        for key2, value2 in oldHotkeys {
            currModifier2 := checkHotkeyModifier(key2)
            currKey2 := (currModifier2 != "") ? StrReplace(key2, currModifier2, "") : key2

            if (InStr(currKey2, ">")) {
                currKey2 := StrSplit(currKey2, ">")[1] . ">"
            }
            else if (InStr(currKey, "<")) {
                currKey2 := StrSplit(currKey2, "<")[1] . "<"
            }

            if (currKey = currKey2) {
                oldHotkeys.Delete(key2)
            }
        }

        oldHotkeys[key] := value
    }

    return oldHotkeys
}

; checks & returns a hotkey modifier string if it exists
;  hotkey - hotkey string to check for modifier
;
; returns modifier
checkHotkeyModifier(hotkey) {
    modifiers := ["[HOLD]", "[REPEAT]"]

    for item in modifiers {
        if (InStr(StrUpper(hotkey), item)) {
            return item
        }
    }

    return ""
}

; splits a hotkey string into different attributes of the hotkey map
; & -> first element becomes main, all others become sub | -> all elements become main
;  currHotkeys - current hotkey map
;
; returns updated hotkeyMap
optimizeHotkeys(currHotkeys) {
    ; get the highest count button in list
    getMaxButton(list) {        
        maxVal := 0
        maxKey := ""   
        for key, value in list {
            if (value.Length > maxVal) {
                maxKey := key
                maxVal := value.Length
            }
        }

        return maxKey
    }

    ; --- FUNCTION ---
    buttonRefs     := Map()
    buttonRefTimes := Map()
    cleanHotkeys   := Map()
    modifiers      := Map()

    ; clean new hotkeys from program to put into proper format
    for key, value in currHotkeys {
        currModifier := checkHotkeyModifier(key)
        currKey := (currModifier = "") ? key : StrReplace(key, currModifier, "")   
        
        if (!IsObject(value)) {
            down := value

            value := Map()
            value["down"] := down
            value["up"] := ""
            value["time"] := ""
        }

        if (InStr(currKey, "&")) {
            addItem := ""
            currHotkey := StrSplit(currKey, "&")

            refs := []
            for item in currHotkey {
                currItem := Trim(item, " `t`r`n")

                addItem .= currItem . "&"
                refs.Push(currItem)
            }

            cleanItem := RTrim(addItem, "&")

            cleanHotkeys[cleanItem] := value
            modifiers[cleanItem] := Trim(StrLower(currModifier), "[] `t`r`n")

            loop refs.Length {
                if (refs[A_Index] != "") {
                    if (!buttonRefs.Has(refs[A_Index])) {
                        buttonRefs[refs[A_Index]] := [cleanItem]
                    }
                    else {
                        buttonRefs[refs[A_Index]].Push(cleanItem)
                    }

                    if (IsObject(value) && value.Has("time") && value["time"] != "") {
                        valueInt := Integer(value["time"])
    
                        if (buttonRefTimes.Has(refs[A_Index])) {
                            if (valueInt < buttonRefTimes[refs[A_Index]]) {
                                buttonRefTimes[refs[A_Index]] := valueInt
                            }
                        }
                        else {
                            buttonRefTimes[refs[A_Index]] := valueInt
                        }
                    }
                }
            }
        }
        else if (InStr(currKey, "|")) {
            currHotkey := StrSplit(currKey, "|")

            ; treat or button combos as 2 separate button definitions
            for item in currHotkey {
                currItem := Trim(item, " `t`r`n")

                cleanHotkeys[currItem] := value
                modifiers[currItem] := Trim(StrLower(currModifier), "[] `t`r`n")

                if (currItem != "") {
                    if (!buttonRefs.Has(currItem)) {
                        buttonRefs[currItem] := [currItem]
                    }
                    else {
                        buttonRefs[currItem].Push(currItem)
                    }

                    if (value.Has("time") && value["time"] != "") {
                        valueInt := Integer(value["time"])
    
                        if (buttonRefTimes.Has(currItem)) {
                            if (valueInt < buttonRefTimes[currItem]) {
                                buttonRefTimes[currItem] := valueInt
                            }
                        }
                        else {
                            buttonRefTimes[currItem] := valueInt
                        }
                    }
                }
            }
        }
        else {
            currItem := Trim(currKey, " `t`r`n")

            cleanHotkeys[currItem] := value
            modifiers[currItem] := Trim(StrLower(currModifier), "[] `t`r`n")

            if (currItem != "") {
                if (!buttonRefs.Has(currItem)) {
                    buttonRefs[currItem] := [currItem]
                }
                else {
                    buttonRefs[currItem].Push(currItem)
                }

                if (value.Has("time") && value["time"] != "") {
                    valueInt := Integer(value["time"])

                    if (buttonRefTimes.Has(currItem)) {
                        if (valueInt < buttonRefTimes[currItem]) {
                            buttonRefTimes[currItem] := valueInt
                        }
                    }
                    else {
                        buttonRefTimes[currItem] := valueInt
                    }
                }
            }
        }
    }

    ; sort unique buttons by number of references to each button in the total
    ; hotkeys, lets me reduce the number of button checks in a loop by only
    ; checking the unique buttons in order of most referenced
    sortedButtonRefs := Map()
    loop buttonRefs.Count {
        maxButton := getMaxButton(buttonRefs)
        if (maxButton = "") {
            continue
        }

        maxRefs := buttonRefs.Delete(maxButton)
        sortedButtonRefs[maxButton] := maxRefs

        ; remove shared references from any buttons outside of max
        for key, value in buttonRefs {
            loop maxRefs.Length {
                currRef := maxRefs[A_Index]

                toDelete := []
                loop value.Length {
                    if (currRef = value[A_Index]) {
                        toDelete.Push(A_Index)
                    }
                }

                loop toDelete.Length {
                    value.RemoveAt(toDelete[A_Index])
                }
            }
        }
    }

    return {
        hotkeys: cleanHotkeys,
        modifiers: modifiers,
        buttonTree: sortedButtonRefs,
        buttonTimes: buttonRefTimes,
    }
}

; check & find most specific hotkey that matches controller state
;  currButton - button that was matched
;  currHotkeys - currHotkeys as set by program
;  status - status result from controller
; 
; returns array of button combo pressed & function from currHotkeys based on controller
checkHotkeys(currButton, currHotkeys, status) {
    ; creates the hotkeyData in the appropriate format
    createHotkeyData(hotkey) {
        down := ""
        up   := ""
        time := ""

        for key, value in currHotkeys.hotkeys[hotkey] {
            if (StrLower(key) = "down") {
                down := value
            }
            else if (StrLower(key) = "up") {
                up := value
            }
            else if (StrLower(key) = "time") {
                time := value
            }
        }

        return {
            hotkey: StrSplit(hotkey, ["&", "|"]), 
            modifier: currHotkeys.modifiers[hotkey],
            function: down,
            release: up, 
            time: time,
        }
    }

    if (!currHotkeys.buttonTree.Has(currButton)) {
        return -1
    }

    ; masking array of hotkeys from other branches in buttontree 
    ; used to check that current pressed key combo is actually a child
    ; of the buttontree[currbutton]
    notCheckArr := []
    for key, value in currHotkeys.buttonTree {
        if (key = currButton) {
            continue
        }

        loop value.length {
            currArr := StrSplit(value[A_Index], "&")
            if (inArray(currButton, currArr)) {
                notCheckArr.Push(value[A_Index])
            }
        }
    }

    maxInvalidAmp := 0
    for item in notCheckArr {
        if (item = "") {
            continue
        }

        hotkeyList := StrSplit(item, "&")

        if (controllerCheckStatus(hotkeyList, status)) {
            maxInvalidAmp := hotkeyList.Length
        }
    }

    checkArr := currHotkeys.buttonTree[currButton]

    maxValidAmp := 0
    maxValidItem := ""
    for item in checkArr {
        if (item = "") {
            continue
        }

        hotkeyList := StrSplit(item, "&")

        if (controllerCheckStatus(hotkeyList, status)) {
            maxValidAmp := hotkeyList.Length
            maxValidItem := item
        }
    }

    ; if the button combo is from a different buttontree branch
    ; or if no valid button combos found
    if (maxInvalidAmp > maxValidAmp || maxValidAmp = 0) {
        return -1
    }

    return createHotkeyData(maxValidItem)
}