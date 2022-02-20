; gets the default hotkeys & formats them into the proper hotkey map
;  config - config taken from main
;
; returns map of default hotkeys
defaultHotkeys(config) {
    newHotkeys := Map()

    for key in StrSplit(config["Hotkeys"]["keys"], ",") {
        ; only add pause hotkey if pausing is enabled
        if (key = "Pause" && config["General"].Has("EnablePause") && config["General"]["EnablePause"] = true) {    
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
    retMap["A|B"] := "Exit"

    return retMap
}

addHotkeys(currHotkeys, newHotkeys) {
    for key, value in newHotkeys {
        currHotkeys[key] := value
    }

    return currHotkeys
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
                if (value > maxVal) {
                    maxKey := key
                    maxVal := value
                }
            }
    
            return maxKey
        }
    
        ; --- FUNCTION ---
        cleanHotkeys := Map()
        buttonCount := Map()
    
        ; clean new hotkeys from program to put into proper format
        for key, value in currHotkeys {
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
    
                cleanHotkeys[RTrim(addItem, "&")] := value
            }
            else if (InStr(key, "|")) {
                currHotkey := StrSplit(key, "|")
    
                ; treat or button combos as 2 separate button definitions
                for item in currHotkey {
                    currItem := Trim(item, " `t`r`n")
    
                    cleanHotkeys[currItem] := value
    
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
    
                cleanHotkeys[currItem] := value
    
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
    
        retHotkeys := Map()
        retHotkeys["hotkeys"] := cleanHotkeys
    
        ; sort unique buttons by number of references to each button in the total
        ; hotkeys, lets me reduce the number of button checks in a loop by only
        ; checking the unique buttons in order of most referenced
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
;  port - controller port
;  ptr - xinput buffer ptr
; 
; returns array of button combo pressed & function from currHotkeys based on controller
checkHotkeys(currButton, currHotkeys, port, ptr) {
    checkArr := []
    for key, value in currHotkeys {
        if (InStr(key, currButton)) {
            checkArr.Push(key)
        }
    }

    ; if only 1 hotkeys references button & button is pressed -> return hotkey
    if (checkArr.Length = 1 && checkArr[1] = currButton) {
        return [toArray(StrSplit(checkArr[1], "&")), currHotkeys[checkArr[1]]]
    }

    maxValidAmp := 0
    maxValidItem := ""
    for item in checkArr {
        if (item = "") {
            continue
        }

        hotkeyList := StrSplit(item, "&")

        if (xCheckStatus(hotKeyList, port, ptr)) {
            maxValidAmp := hotkeyList.Length
            maxValidItem := item
        }
    }

    if (maxValidAmp = 0) {
        return -1
    }

    return [toArray(StrSplit(maxValidItem, "&")), currHotkeys[maxValidItem]]
}