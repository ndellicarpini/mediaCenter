; combines the hotkeys from currHotkeys & newHotkeys, preferring newHotkeys where keys overlap
;  currHotkeys - the current hotkeys to add to / replace
;  newHotkeys - new hotkeys to add to currHotkeys
;
; returns the combination of currHotkeys & newHotkeys
addHotkeys(currHotkeys, newHotkeys) {
    oldHotkeys := ObjDeepClone(currHotkeys)

    ; parse currHotkeys & replace shared hotkeys with newHotkeys
    for key, value in oldHotkeys {
        if (newHotkeys.Has(key)) {
            for key2, value2 in newHotkeys[key] {
                currModifier := checkHotkeyModifier(key2)
                currKey := (currModifier != "") ? StrReplace(key2, currModifier, "") : key2
        
                if (InStr(currKey, ">")) {
                    currKey := StrSplit(currKey, ">")[1] . ">"
                }
                else if (InStr(currKey, "<")) {
                    currKey := StrSplit(currKey, "<")[1] . "<"
                }
        
                for key3, value3 in oldHotkeys[key] {
                    currModifier2 := checkHotkeyModifier(key3)
                    currKey2 := (currModifier2 != "") ? StrReplace(key3, currModifier2, "") : key3
        
                    if (InStr(currKey2, ">")) {
                        currKey2 := StrSplit(currKey2, ">")[1] . ">"
                    }
                    else if (InStr(currKey, "<")) {
                        currKey2 := StrSplit(currKey2, "<")[1] . "<"
                    }
        
                    if (currKey = currKey2) {
                        oldHotkeys[key].Delete(key3)
                    }
                }
        
                oldHotkeys[key][key2] := value2
            }
        }
    }

    ; add newHotkeys to currHotkeys that didn't exist in currHotkeys
    for key, value in newHotkeys {
        if (!oldHotkeys.Has(key)) {
            oldHotkeys[key] := value
        }
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

; converts a map of hotkeys into an object more appropriate to use while checking pressed keys
;  currHotkeys - current hotkey map
;
; returns {
;   hotkeys     - currHotkeys but splitting | hotkeys into unique entries
;   modifiers   - map of hotkey modifiers using the hotkeys as keys
;   buttonTree  - map using every unique key as keys, and an array of hotkeys using that key as values
;   buttonTimes - map storing the times required to trigger function for every hotkey
; }
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

    ; clean out ors from hotkey
    tempHotkeys := Map()
    for key, value in currHotkeys {
        if (!InStr(key, "|")) {
            tempHotkeys[key] := value
            continue
        }

        currModifier := checkHotkeyModifier(key)
        currKey := (currModifier = "") ? key : StrReplace(key, currModifier, "")  
        for item in StrSplit(currKey, "|") {
            tempHotkeys[currModifier . item] := value
        }
    }

    ; splits hotkeys into modifiers, times, & unique keys
    for key, value in tempHotkeys {
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
    buttonTree := Map()
    loop buttonRefs.Count {
        maxButton := getMaxButton(buttonRefs)
        if (maxButton = "") {
            continue
        }

        maxRefs := buttonRefs.Delete(maxButton)
        buttonTree[maxButton] := maxRefs

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
        buttonTree: buttonTree,
        buttonTimes: buttonRefTimes,
    }
}