; class for the list of running threads in main
;  items - actual map of running threads
;  threadHeader - prefix to attach to thread scripts
class ThreadList {
    items := Map()
    threadHeader := "
    (
        #Include 'lib-mc\std.ahk'

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

            Loop {
                ; i guess i need to keep updating the value in the loop, otherwise c_status will clear??
                ; maybe some memory shenanigans (i dont like this)

                ; this seems to run a little fast? without SetBatchLines need to come up with another
                ; way to reduce script's desired cpu

                c_config := CriticalObject(T_Args[1])
                c_status := CriticalObject(T_Args[2])

                for key, value in c_status {

                    ; check for status starting with curr (supposed to be programs to be checked if running)
                    if (InStr(key, "curr") && IsObject(value)) {
                        configKey := StrReplace(key, "curr")

                        ; if there is list of type of program, use checkexe/wndwlist
                        if (c_config.Has("List" . configKey)) {
                            listKey := "List" . configKey
                            
                            for key2, value2 in c_config[listKey] {
                                listKeyArr := StrSplit(key2, "_")

                                if (c_status[key].Has(listKeyArr[1])) {
                                    if (StrLower(listKeyArr[2]) = "exe") {
                                        c_status[key][listKeyArr[1]] := checkEXEList(c_config[listKey][key2])
                                    }
                                    else if (StrLower(listKeyArr[2]) = "wndw") {
                                        c_status[key][listKeyArr[1]] := checkWNDWList(c_config[listKey][key2])
                                    }
                                }
                            }                         
                        }

                        Sleep(50)
                        
                        ; if program is running, set variable in curr[Status]
                        if (c_config.Has(configKey) && IsObject(c_config[configKey])) {
                            for key2, value2 in c_config[configKey] {   
                                
                                if (c_config[configKey].Has(key2)) {
                                    c_status[key][key2] := ProcessExist(c_config[configKey][key2]) ? c_config[configKey][key2] : ""
                                }
                            }
                        }

                        Sleep(50)
                    }
                }

                Sleep(100)

                ; add mode switcher
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