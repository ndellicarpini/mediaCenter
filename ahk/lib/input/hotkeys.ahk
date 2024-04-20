; combines the hotkeys from currHotkeys & newHotkeys, preferring newHotkeys where keys overlap
;  currHotkeys - the current hotkeys to add to / replace
;  newHotkeys - new hotkeys to add to currHotkeys
;
; returns the combination of currHotkeys & newHotkeys
addHotkeys(currHotkeys, newHotkeys) {
    oldHotkeys := ObjDeepClone(currHotkeys)

    ; parse currHotkeys & replace shared hotkeys with newHotkeys
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
            else if (InStr(currKey2, "<")) {
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
    modifiers := ["[HOLD]", "[REPEAT]", "[PATTERN]"]

    for item in modifiers {
        if (InStr(StrUpper(hotkey), item)) {
            return item
        }
    }

    return ""
}

; checks if the input hotkey is matched in the controller status
;  hotkey - string key for hotkey
;  status - controller status
;  currInput - hotkeys 
;  currInput - hotkey input status 
;
; returns 
;  "full" - complete match of hotkey
;  "partial" - partial match of "&" hotkey
;  "patternNext" - move the patternPos forward
;  "" - miss
checkHotkey(hotkey, status, currHotkeys, currInput) {
    cleanHotkey := hotkey
    if (currHotkeys[cleanHotkey]["modifier"] = "[PATTERN]") {
        patternArr := StrSplit(cleanHotkey, ",")

        if (currInput.Has(cleanHotkey) && patternArr.Length >= (currInput[cleanHotkey]["patternPos"] + 1)) {
            patternNext := true
            for item in StrSplit(patternArr[currInput[cleanHotkey]["patternPos"] + 1], "&") {
                patternNext := patternNext && inputCheckStatus(item, status)
            }

            if (patternNext) {
                return "patternNext"
            }
            
            cleanHotkey := patternArr[currInput[cleanHotkey]["patternPos"]]
        }
        else {
            cleanHotkey := patternArr[1]
        }
    }

    full := true
    partial := false
    for item in StrSplit(cleanHotkey, "&") {
        statusResult := inputCheckStatus(item, status)
        full := full && statusResult
        partial := partial || statusResult
    }

    if (full) {
        return "full"
    }
    else if (partial) {
        return "partial"
    }
    else {
        return ""
    }
}

; converts hotkeys into an object more appropriate to use while checking keys
;  currHotkeys - current hotkey map
;  defaultTime - default button time
;
; returns new hotkey map
optimizeHotkeys(currHotkeys, defaultTime) {
    retHotkeys := Map()
    for key, value in currHotkeys {
        modifier := checkHotkeyModifier(key)
        hotkey := Map()

        baseTime := defaultTime
        if (modifier = "[REPEAT]") {
            baseTime := 400
        }
        else if (modifier = "[PATTERN]") {
            baseTime := 5000
        }

        if (IsObject(value)) {
            hotkey["modifier"] := modifier
            hotkey["down"] := (value.Has("down")) ? value["down"] : ""
            hotkey["up"] := (value.Has("up")) ? value["up"] : ""
            hotkey["time"] := Integer((value.Has("time")) ? value["time"] : baseTime)
        }
        else {
            hotkey["modifier"] := modifier
            hotkey["down"] := value
            hotkey["up"] := ""
            hotkey["time"] := baseTime
        }

        cleanKey := StrUpper((modifier != "") ? StrReplace(key, modifier) : key)
        if (InStr(cleanKey, "|")) {
            for item in StrSplit(cleanKey, "|") {
                retHotkeys[item] := hotkey
            }
        }
        else {
            retHotkeys[cleanKey] := hotkey
        }
    }

    return retHotkeys
}