class Madden19Program extends EAGameProgram {
    _postLaunchDelay := 1500
    _mouseMoveDelay  := 20000

    _postLaunch() {
        this.send("{Enter}")
    }
}