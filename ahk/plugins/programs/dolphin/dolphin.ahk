class DolphinEmulator extends Emulator {
    ; _pause() {
    ;     this.send("{F10}", 150)
    ; }

    ; _resume() {
    ;     this._pause()
    ; }
    
    ; _saveState(slot) {
    ;     this.send("{Shift down}")
    ;     Sleep(100)
    ;     this.send("{F1}")
    ;     Sleep(100)
    ;     this.send("{Shift up}")
    ; }

    ; _loadState(slot) {
    ;     this.send("{F1}")
    ; }

    ; _reset() {
    ;     this.send("r")
    ; }

    ; _fastForward() {
    ;     if (this.fastForwarding) {
    ;         this.send("{Tab up}")
    ;     }
    ;     else {
    ;         this.send("{Tab down}")
    ;     }
    ; }
}