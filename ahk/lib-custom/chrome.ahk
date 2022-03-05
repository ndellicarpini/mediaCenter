chromeControls() {
    MsgBox("having sex with your moother")
}

chromePIP() {
    global globalRunning

    currProgram := getStatusParam("currProgram")

    if (currProgram != "") {
        globalRunning[currProgram].restore()
        Send("{Alt Down}p{Alt Up}")
        
        for key, value in globalRunning[currProgram].pauseOptions {
            if (InStr(key, "Picture-in-Picture")) {
                newKey := ""

                if (InStr(key, "Enable")) {
                    newKey := StrReplace(key, "Enable", "Disable")                    
                }
                else {
                    newKey := StrReplace(key, "Disable", "Enable")
                }

                globalRunning[currProgram].pauseOptions[newKey] := value
                globalRunning[currProgram].pauseOptions.Delete(key)

                loop globalRunning[currProgram].pauseOrder.Length {
                    if (globalRunning[currProgram].pauseOrder[A_Index] = key) {
                        globalRunning[currProgram].pauseOrder[A_Index] := newKey
                        break
                    }
                }

                break
            }
        }
    }
}