class XCOM2Program extends SteamGameProgram {
    __New(args*) {
        super.__New(args*)

        exePath := ""
        if (Type(this.dir) = "Array") {
            for dir in this.dir {
                tempPath := validateDir(dir) . "XCOM 2\Binaries\Win64\XCom2.exe"
                if (FileExist(tempPath)) {
                    exePath := tempPath
                    break
                }
            }
        }

        if (exePath != "") {
            this.defaultArgs.InsertAt(1, '"' . exePath . '"')
        }
    }
}