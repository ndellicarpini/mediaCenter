; --- DEFAULT WINDOWS GAME ---
class WinGameProgram extends Program {
    _launch(args*) {
        try {
            cleanArgs := ObjDeepClone(args)

            ; re-orders the default args to be after the program filepath
            ; that way the filepath is always the first arg
            if (this.defaultArgs.Length > 0) {
                toReorder := []
                ; parse args
                loop args.Length {
                    if (inArray(args[A_Index], this.defaultArgs)) {
                        toReorder.Push(A_Index)
                    }
                }
                
                tempArgs := []
                loop toReorder.Length {
                    tempArgs.Push(cleanArgs.RemoveAt(toReorder[toReorder.Length - (A_Index - 1)]))
                }

                loop tempArgs.Length {
                    cleanArgs.InsertAt(2, tempArgs[A_Index])
                }
            }

            game := cleanArgs.RemoveAt(1)
            pathArr := StrSplit(game, "\")
        
            exe := pathArr.RemoveAt(pathArr.Length)
            path := LTrim(joinArray(pathArr, "\"), '"' . '"')

            if (Type(this.dir) != "Array") {
                currDir := this.dir

                this.dir := [path]
                if (currDir != "") {
                    this.dir.Push(currDir)
                }
            }
            else {
                this.dir.Push(path)
            }
        
            RunAsUser(game, cleanArgs, path)
        }
        catch {
            return false
        }
    }
}