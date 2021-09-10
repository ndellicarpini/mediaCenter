; checks if the toRead string is a file, if not then returns toRead
;  toRead - either filepath string or normal string
;
; returns either file contents of toRead or the original toRead string
fileOrString(toRead) {
    retString := ""

    if (FileExist(toRead)) {
		file := FileOpen(toRead, "r")
		retString := file.Read()
		file.Close()
	}
	else {
		retString := toRead
	}

    return retString
}