; creates & shows the load screen
;
; returns null
createLoadScreen() {
    global globalConfig
    global globalStatus

    guiObj := Gui(GUIOPTIONS, GUILOADTITLE)

	try {
		guiObj := customLoadScreen(guiObj)
	}
	catch {
		guiObj.BackColor := COLOR1
        guiSetFont(guiObj, "italic s30")

        guiObj.Add("Text", "vLoadText Right x0 y" . percentHeight(0.92, false) " w" . percentWidth(0.985, false), globalStatus["loadscreen"]["text"])
	}

    guiObj.Show("x" . MONITORX . " y" . MONITORY . " NoActivate w" . percentWidth(1) . " h" . percentHeight(1))
}

; activates the load screen
;
; retuns null
activateLoadScreen() {
	if (WinShown(GUILOADTITLE)) {
		WinActivate(GUILOADTITLE)
	}
}

; activates & updates the text the load screen
;  activate - if to activate the loadscreen
;
; returns null
updateLoadScreen(activate := true) {
	global globalStatus

	loadObj := getGUI(GUILOADTITLE)
	if (loadObj) {
		loadObj["LoadText"].Text := globalStatus["loadscreen"]["text"]
		loadObj["LoadText"].Redraw()
	}
	else if (activate) {
		createLoadScreen()
		Sleep(100)
	}
	
	pauseObj := getGUI(GUIPAUSETITLE)
	if (pauseObj) {
		destroyPauseMenu()
	}

	if (activate) {
		activateLoadScreen()
	}
}

; destroys the load screen
;
; returns null
destroyLoadScreen() {
    if (getGUI(GUILOADTITLE)) {
        getGUI(GUILOADTITLE).Destroy()
    }
}

; sets the text of the load screen & activates it
;  text - new load screen text
;
; returns null
setLoadScreen(text) {
	global globalStatus

    MouseMove(percentWidth(1, false), percentHeight(1, false))

    globalStatus["loadscreen"]["show"] := true
    globalStatus["loadscreen"]["text"] := text
    updateLoadScreen()
}

; resets the text of the load screen & deactivates it
;
; returns null
resetLoadScreen() {
	global globalStatus

	globalStatus["loadscreen"]["show"] := false
	SetTimer(DelayResetText.Bind(globalStatus["loadscreen"]["text"]), -1000)

	return

	DelayResetText(currText) {
		global globalConfig

		; don't reset if the text has been changed by another loadText update
		if (globalStatus["loadscreen"]["text"] != currText) {
			return
		}

		globalStatus["loadscreen"]["text"] := (globalConfig["GUI"].Has("DefaultLoadText")) 
			? globalConfig["GUI"]["DefaultLoadText"] : "Now Loading..."
			
		updateLoadScreen(false)

		return
	}
}

; spin waits until either timeout or successful internet connection
;  timeout - seconds to wait
;
; returns true if connected to internet
internetLoadScreen(timeout := 30) {
	count := 0
	wsaData := Buffer(408, 0)
		
	setLoadScreen("Waiting for Internet...")

	if (DllCall("Ws2_32\WSAStartup", "UShort", 0x0202, "Ptr", wsaData.Ptr)) {
		resetLoadScreen()
		return false
	}
	
	addrPtr := 0
	while (count < timeout) {
		try {
			if (DllCall("Ws2_32\GetAddrInfoW", "WStr", "dns.msftncsi.com", "WStr", "http", "Ptr", 0, "Ptr*", &addrPtr)) {		
				count += 1
				Sleep(1000)

				setLoadScreen("Waiting for Internet... (" . (timeout - count) . ")")
				continue
			}

			family  := NumGet(addrPtr + 4, 0, "Int")
			addrLen := NumGet(addrPtr + 16, 0, "Ptr")
			addr    := NumGet(addrPtr + 16, 16, "Ptr")

			DllCall("Ws2_32\WSAAddressToStringW", "Ptr", addr, "UInt", addrLen, "Ptr", 0, "Str", wsaData.Ptr, "UInt*", 204)
			DllCall("Ws2_32\FreeAddrInfoW", "Ptr", addrPtr)

			http := ComObject("WinHttp.WinHttpRequest.5.1")

			if (family = 2 && StrGet(wsaData) = "131.107.255.255:80") {
				http.Open("GET", "http://www.msftncsi.com/ncsi.txt")
			}
			else if (family = 23 && StrGet(wsaData) = "[fd3e:4f5a:5b81::1]:80") {
				http.Open("GET", "http://ipv6.msftncsi.com/ncsi.txt")
			}

			http.Send()

			if (http.ResponseText = "Microsoft NCSI") {
				DllCall("Ws2_32\WSACleanup")
				resetLoadScreen()
				return true
			}
		}
	
		count += 1
		Sleep(1000)

		setLoadScreen("Waiting for Internet... (" . (timeout - count) . ")")
	}

	DllCall("Ws2_32\WSACleanup")
	resetLoadScreen()
	return false
}