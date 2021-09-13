; class for the list of running threads in main
;  items - actual map of running threads
;  threadHeader - prefix to attach to thread scripts
class ThreadList {
    items := Map()
    threadHeader := "
    (
        #Include 'mclib\std.ahk'

        T_Args := StrSplit(A_Args[1], '.')

    )"
    
    ; create the thread list and every running thread
    ;  config - critical object of data taken from global config
    ;  status - critical object of current status of program
    __New(configPtr, statusPtr) {
        this.items["programThread"] := this.programThread(ptrListToString(configPtr, statusPtr))
    }

    ; creates the thread to monitor which programs are running & updates mode appropriately
    ;  pointers - period seperated string containing pointers for critical objects config & status
    ;
    ; returns null
    programThread(pointers) {
        return AhkThread(this.threadHeader . "
        (
            c_config := CriticalObject(T_Args[1])
            c_status := CriticalObject(T_Args[2])
        
            Loop {
                c_status.currHome := ProcessExist(c_config.homeEXE) ? c_config.homeEXE : ""
                c_status.currGameLauncher := ProcessExist(c_config.gameLauncherEXE) ? c_config.gameLauncherEXE : ""
                c_status.currBrowser := ProcessExist(c_config.browserEXE) ? c_config.browserEXE : ""
                
                if (c_status.currGame = "" || !ProcessExist(c_status.currGame)) {
                    c_status.currGame := checkEXEList(c_config.winGameList, c_config.emuGameList)
                }

                Sleep(100)
        
                if (!WinShown(c_status.currOverride)) {
                    c_status.currOverride := checkWNDWList(c_config.loadOverrideList)
                }

                Sleep(100)
        
                if (c_status.currOverride != "") {
                    c_status.mode := "override"
                }
                else if (c_status.mode != "boot" || c_status.mode != "shutdown" 
                || c_status.mode != "restart" || c_status.mode != "load")  {
                    if (c_status.currBrowser != "") {
                        c_status.mode := "browser"
                    }
                    else if (c_status.currGame != "") {
                        c_status.mode := "game"
                    }
                    else if (c_status.currGameLauncher != "") {
                        c_status.mode := "gameLauncher"
                    }
                    else if (c_status.currHome != "") {
                        c_status.mode := "home"
                    }
                    else {
                        c_status.mode := ""
                    }
                }

                Sleep(100)
            }
        )", pointers)
    }
    
    ; terminates a thread based on threadName and removes it from the threadlist
    ;  threadName - key for thread to be stopped & removed
    ;
    ; returns null
    closeThread(threadName) {
        this.items[threadName].ahkTerminate()
        this.items.Delete(threadName)
    }
    
    ; terminates all threads in the threadlist
    ;
    ; returns null
    closeAllThreads() {
        for key, value in this.items {
            this.CloseThread(key)
        }
    }
}