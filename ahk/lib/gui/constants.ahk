global GUI_OPTIONS := "-DPIScale -Resize -Caption"

global DEFAULT_MONITOR := 0
global SIZE := ""
global FONT := ""
global FONT_COLOR := ""
global COLOR1 := ""
global COLOR2 := ""
global COLOR3 := ""

global INTERFACES := Map(
    "message", Map(
        "wndw", "AHKGUIMESSAGE",
        "class", "MessageInterface"
    ),
    "notification", Map(
        "wndw", "AHKGUINOTIFICATION",
        "class", "NotificationInterface"
    ),
    "choice", Map(
        "wndw", "AHKGUICHOICE",
        "class", "ChoiceInterface"
    ),
    "input", Map(
        "wndw", "AHKGUIINPUT",
        "class", "InputInterface"
    ),
    "keyboard", Map(
        "wndw", "AHKGUIKEYBOARD",
        "class", "KeyboardInterface"
    ),
    "loadscreen", Map(
        "wndw", "AHKGUILOADSCREEN",
        "class", "LoadscreenInterface"
    ),
    "pause", Map(
        "wndw", "AHKGUIPAUSE",
        "class", "PauseInterface"
    ),
    "power", Map(
        "wndw", "AHKGUIPOWER",
        "class", "PowerInterface"
    ),
    "program", Map(
        "wndw", "AHKGUIPROGRAM",
        "class", "ProgramInterface"
    ),
    "volume", Map(
        "wndw", "AHKGUIVOLUME",
        "class", "VolumeInterface"
    )
)