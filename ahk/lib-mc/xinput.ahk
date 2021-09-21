; class containing the current status of all buttons & axis on an xinput controller
;  port - port of xinput device (0 -> (MaxXInputControllers - 1))
;  dllAddress - dll address for xinput library as gotten from load library & getprocaddress
;  connected - true if xinput device connected, false else
class XController {
    port := -1
    dllAddress := ""
    connected := false

    HOME    := false
    START   := false
    SELECT  := false

    A       := false
    B       := false
    X       := false
    Y       := false
    LB      := false
    RB      := false
    LSB     := false
    RSB     := false

    DU      := false
    DD      := false
    DL      := false
    DR      := false

    ; all fractional values based on max ranges
    ; max range -32768-32767
    LSX     := 0
    LSY     := 0
    RSX     := 0
    RSY     := 0

    ; max range 0-255
    LT      := 0
    RT      := 0

    __New(port, dllAddress) {
        this.port := port
        this.dllAddress := dllAddress
    }

    ; checks connection status of controller & updates all buttons & axis
    ;
    ; returns null
    update() {
        xBuffer := BufferAlloc(16)
        xResult := DllCall(this.dllAddress, "uint", this.port, "ptr", xBuffer.Ptr)

        this.connected := (xResult != 1167) ? true : false
        
        if (!this.connected) {
            this.reset()
        }
        else {
            this.LT  := NumGet(xBuffer, 6, "uchar") / 255
            this.RT  := NumGet(xBuffer, 7, "uchar") / 255

            this.LSX := NumGet(xBuffer, 8, "short") / 32768
            this.LSY := NumGet(xBuffer, 10, "short") / 32768
            this.RSX := NumGet(xBuffer, 12, "short") / 32768
            this.RSY := NumGet(xBuffer, 14, "short") / 32768

            buttons  := NumGet(xBuffer, 4, "ushort")

            this.DU      := (buttons & 0x0001) ? true : false
            this.DD      := (buttons & 0x0002) ? true : false
            this.DL      := (buttons & 0x0004) ? true : false
            this.DR      := (buttons & 0x0008) ? true : false

            this.A       := (buttons & 0x1000) ? true : false
            this.B       := (buttons & 0x2000) ? true : false
            this.X       := (buttons & 0x4000) ? true : false
            this.Y       := (buttons & 0x8000) ? true : false
            
            this.LB      := (buttons & 0x0100) ? true : false
            this.RB      := (buttons & 0x0200) ? true : false
            this.LSB     := (buttons & 0x0040) ? true : false
            this.RSB     := (buttons & 0x0080) ? true : false
            
            this.SELECT  := (buttons & 0x0020) ? true : false
            this.START   := (buttons & 0x0010) ? true : false
            this.HOME    := (buttons & 0x0400) ? true : false
        }
    }

    ; resets the controller's buttons & axis values back to the default
    ;
    ; returns null
    reset() {
        this.HOME    := false
        this.START   := false
        this.SELECT  := false

        this.A       := false
        this.B       := false
        this.X       := false
        this.Y       := false
        this.LB      := false
        this.RB      := false
        this.LSB     := false
        this.RSB     := false

        this.DU      := false
        this.DD      := false
        this.DL      := false
        this.DR      := false

        this.LSX     := 0
        this.LSY     := 0
        this.RSX     := 0
        this.RSY     := 0

        this.LT      := 0
        this.RT      := 0
    }
}

; initializes the xinput library if the dll file exists
;  dll - path to xinput dll
;
; returns either empty string if no dll, or xinput library
xLoadLib(dll) {
    return DllCall("LoadLibrary", "str", dll)
}

; frees the xinput library if it was loaded
;  lib - library if it is loaded
;
; returns 0?
xFreeLib(lib) {
    if (lib = 0) {
        return 0
    }

    return DllCall("FreeLibrary", "uint", lib)
}

; intializes the set of controller objects based on the maxController count
;  lib - loaded xinput library
;  maxControllers - maximum number of xinput devices to initialize
;
; returns map of controller objects
xInitialize(lib, maxControllers) {
    controllerMap := Map()

    if (lib != 0) {
        xAddress := DllCall("GetProcAddress", "uint", lib, "uint", 100)

        Loop maxControllers {
            controllerMap[(A_Index - 1)] := XController.New((A_Index - 1), xAddress)
        }
    }

    return controllerMap
}