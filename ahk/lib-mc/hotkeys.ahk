; gets the default hotkeys & formats them into the proper hotkey map
;  config - config taken from main
;
; returns map of default hotkeys
defaultHotkeys(config) {
    newHotkeys := Map()

    for key in config["Hotkeys"] {
        ; only add pause hotkey if pausing is enabled
        if (StrLower(key) = "pausemenu" && config["General"].Has("EnablePause") && config["General"]["EnablePause"]) {    
            newHotkeys[config["Hotkeys"][key]] := key
        }
        else {
            newHotkeys[config["Hotkeys"][key]] := key
        }
    }

    return newHotkeys 
}

; creates hotkey map for when an error message is on screen
;
; returns hotkey map
errorHotkeys() {
    retMap := Map()
    retMap["A|B"] := "ExitProgram"

    return retMap
}

addHotkeys(currHotkeys, newHotkeys) {
    for key, value in newHotkeys {
        currHotkeys[key] := value
    }

    return currHotkeys
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
    cleanHotkeys := Map()
    buttonRefs := Map()
    modifiers := Map()

    ; clean new hotkeys from program to put into proper format
    for key, value in currHotkeys {
        currModifier := checkHotkeyModifier(key)
        currKey := (currModifier = "") ? key : StrReplace(key, currModifier, "")            

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
        buttonTree: sortedButtonRefs
    }
}

; check & find most specific hotkey that matches controller state
;  currButton - button that was matched
;  currHotkeys - currHotkeys as set by program
;  port - controller port
;  ptr - xinput buffer ptr
; 
; returns array of button combo pressed & function from currHotkeys based on controller
checkHotkeys(currButton, currHotkeys, port, ptr) {
    ; creates the hotkeyData in the appropriate format
    createHotkeyData(hotkey) {
        downFunction := ""
        upFunction   := ""

        if (IsObject(currHotkeys.hotkeys[hotkey])) {
            for key, value in currHotkeys.hotkeys[hotkey] {
                if (StrLower(key) = "down") {
                    downFunction := value
                }
                else if (StrLower(key) = "up") {
                    upFunction := value
                }
            }
        }
        else {
            downFunction := currHotkeys.hotkeys[hotkey]
        }

        return {
            hotkey: StrSplit(hotkey, ["&", "|"]), 
            modifier: currHotkeys.modifiers[hotkey],
            function: downFunction, 
            release: upFunction, 
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
            currArr := StrSplit(value[A_Index], ["&", "|"])
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

        hotkeyList := StrSplit(item, ["&", "|"])

        if (xCheckStatus(hotKeyList, port, ptr)) {
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

        hotkeyList := StrSplit(item, ["&", "|"])

        if (xCheckStatus(hotKeyList, port, ptr)) {
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