regexClean(text) {
	retString := StrReplace(text, "\", "\\")
	retString := StrReplace(retString, ".", "\.")
	retString := StrReplace(retString, "*", "\*")
	retString := StrReplace(retString, "?", "\?")
	retString := StrReplace(retString, "+", "\+")
	retString := StrReplace(retString, "[", "\[")
	retString := StrReplace(retString, "{", "\{")
	retString := StrReplace(retString, "|", "\|")
	retString := StrReplace(retString, "(", "\(")
	retString := StrReplace(retString, ")", "\)")
	retString := StrReplace(retString, "^", "\^")
	retString := StrReplace(retString, "$", "\$")
	
	return retString
}