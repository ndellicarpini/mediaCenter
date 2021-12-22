; gets the default hotkeys & formats them into the proper hotkey map
;  config - config taken from main
;  controller - controller object to check if hotkey exists
;
; returns map of default hotkeys
defaultHotkeys(config, controller) {
    newHotkeys := Map()

    for key in StrSplit(config["Hotkeys"]["keys"], ",") {
        if (key = "Pause" && config["General"].Has("EnablePause") && config["General"]["EnablePause"] = true) {    
            newHotkeys[config["Hotkeys"][key]] := key
        }
        else {
            newHotkeys[config["Hotkeys"][key]] := key
        }
    }

    return addHotkeys(Map(), addKeyListString(newHotkeys), controller) 
}

; splits a hotkey string into different attributes of the hotkey map
; & -> first element becomes main, all others become sub | -> all elements become main
;  hotkeyMap - current hotkey map
;  newHotkeys - hotkeys to add to map
;  controller - controller object to check if hotkey exists
;
; returns updated hotkeyMap
addHotkeys(oldHotkeys, newHotkeys, controller) {
    ; get the counts of each button in map
    getButtonCount(hotkeys) {
        countMap := Map()
        for key, value in hotkeys {
            currKey := StrSplit(key, "&")
            
            for item in currKey {
                if (item != "") {
                    if (countMap.Has(item)) {
                        countMap[item] += 1
                    }
                    else {
                        countMap[item] := 1
                    }
                }
            }
        }

        return countMap
    }

    ; get the highest count button in list
    getMaxButton(list) {        
        maxVal := 0
        maxKey := ""   
        for key, value in list {
            if (value > maxVal) {
                maxKey := key
                maxVal := value
            }
        }

        return maxKey
    }

    ; create a map of buttons & functions for easier parsing
    createButtonFuncMap(hotkeys, currMap, currItem) {
        for key, value in hotkeys {
            if (value.Has("function")) {
                currMap[currItem . key] := value["function"]
            }

            if (value.Has("subHotkeys")) {
                currMap := createButtonFuncMap(value["subHotkeys"], currMap, currItem . key . "&")
            }
        }

        return currMap
    }
    
    ; ; recursively creates the return hotkey map
    ; createHotkeyMap(currHotkeys) {
    ;     ; MsgBox(toString(currHotkeys))

    ;     retHotkeys := Map()
    ;     while (currHotkeys.Count > 0) {
    ;         local currButton := getMaxButton(getButtonCount(currHotkeys))
    
    ;         currList := Map()
    ;         ; MsgBox(currButton)
    ;         retHotkeys[currButton] := Map()
    ;         for key, value in currHotkeys {
    ;             if (InStr(key, currButton)) {
    ;                 if (key = currButton) {
    ;                     retHotkeys[currButton]["function"] := value
    ;                 }
    ;                 else {
    ;                     currList[(InStr(key, currButton . "&") 
    ;                         ? StrReplace(key, currButton . "&") : StrReplace(key, "&" . currButton))] := value
    ;                 }

    ;                 currHotkeys.Delete(key)
    ;             }
    ;         }

    ;         ; MsgBox(toString(currButton) . " " . toString(currList))
    ;         ; MsgBox(toString(currList))
    ;         if (currList.Count > 0) {
                
    ;             retHotkeys[currButton]["subHotkeys"] := createHotkeyMap(currList)
    ;             ; MsgBox(toString(retHotkeys))
    ;         }
    ;     }

    ;     ; MsgBox(toString(retHotkeys))

    ;     return retHotkeys
    ; }

    ; --- FUNCTION ---
    cleanHotkeys := Map()
    buttonCount := Map()

    for key in StrSplit(newHotkeys["keys"], ",") {
        if (InStr(key, "&")) {
            addItem := ""
            currHotkey := StrSplit(key, "&")

            for item in currHotkey {
                currItem := Trim(item, " `t`r`n")

                addItem .= currItem . "&"

                if (currItem != "") {
                    if (!buttonCount.Has(currItem)) {
                        buttonCount[currItem] := 1
                    }
                    else {
                        buttonCount[currItem] += 1
                    }
                }
            }

            cleanHotkeys[RTrim(addItem, "&")] := newHotkeys[key]
        }
        else if (InStr(key, "|")) {
            currHotkey := StrSplit(key, "|")

            for item in currHotkey {
                currItem := Trim(item, " `t`r`n")

                cleanHotkeys[currItem] := newHotkeys[key]

                if (currItem != "") {
                    if (!buttonCount.Has(currItem)) {
                        buttonCount[currItem] := 1
                    }
                    else {
                        buttonCount[currItem] += 1
                    }
                }
            }
        }
        else {
            currItem := Trim(key, " `t`r`n")

            cleanHotkeys[currItem] := newHotkeys[key]

            if (currItem != "") {
                if (!buttonCount.Has(currItem)) {
                    buttonCount[currItem] := 1
                }
                else {
                    buttonCount[currItem] += 1
                }
            }
        }
    }

    if (oldHotkeys.Has("hotkeys")) {
        for key, value in oldHotkeys["hotkeys"] {
            if (InStr(key, "&")) {
                currHotkey := StrSplit(key, "&")
    
                for item in currHotkey {
                    if (item != "") {
                        if (!buttonCount.Has(item)) {
                            buttonCount[item] := 1
                        }
                        else {
                            buttonCount[item] += 1
                        }
                    }    
                }
            }
            else {
                if (key != "") {
                    if (!buttonCount.Has(key)) {
                        buttonCount[key] := 1
                    }
                    else {
                        buttonCount[key] += 1
                    }
                }
            }
    
            if (!cleanHotkeys.Has(key)) {
                cleanHotkeys[key] := value
            }
        }
    }

    retHotkeys := Map()
    retHotkeys["hotkeys"] := cleanHotkeys

    uniqueButtons := []
    loop buttonCount.Count {
        maxButton := getMaxButton(buttonCount)
        uniqueButtons.Push(maxButton)

        buttonCount.Delete(maxButton)
    }
      
    retHotkeys["uniqueKeys"] := uniqueButtons

    return retHotkeys
}

; check & find most specific hotkey that matches controller state
;  currButton - button that was matched
;  currHotkeys - currHotkeys as set by program
;  controller - controller status
; 
; returns function from currHotkeys based on controller
checkHotkeys(currButton, currHotkeys, controller) {
    checkArr := []
    for key, value in currHotkeys {
        if (InStr(key, currButton)) {
            checkArr.Push(key)
        }
    }

    if (checkArr.Length = 1) {
        return currHotkeys[checkArr[1]]
    }

    maxValidAmp := 0
    maxValidItem := ""
    for item in checkArr {
        hotkeyList := StrSplit(item, "&")

        if (xCheckController(controller, hotkeyList)) {
            maxValidAmp := hotkeyList.Length
            maxValidItem := item
        }
    }

    if (maxValidAmp = 0) {
        return currHotkeys[checkArr[1]]
    }

    return currHotkeys[maxValidItem]
}