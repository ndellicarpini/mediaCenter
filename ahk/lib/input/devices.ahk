; device names from SDL3
; https://github.com/libsdl-org/SDL/blob/main/src/joystick/controller_list.h
global SDL_DEVICE_NAMES := Map(
    "0079-181a", ["PS3 Controller", ""],	; Venom Arcade Stick
    "0079-1844", ["PS3 Controller", ""],	; From SDL
    "044f-b315", ["PS3 Controller", ""],	; Firestorm Dual Analog 3
    "044f-d007", ["PS3 Controller", ""],	; Thrustmaster wireless 3-1
    "046d-c24f", ["PS3 Controller", ""],	; Logitech G29 (PS3)
    "054c-0268", ["PS3 Controller", ""],	; Sony PS3 Controller
    "056e-200f", ["PS3 Controller", ""],	; From SDL
    "056e-2013", ["PS3 Controller", ""],	; JC-U4113SBK
    "05b8-1004", ["PS3 Controller", ""],	; From SDL
    "05b8-1006", ["PS3 Controller", ""],	; JC-U3412SBK
    "06a3-f622", ["PS3 Controller", ""],	; Cyborg V3
    "0738-3180", ["PS3 Controller", ""],	; Mad Catz Alpha PS3 mode
    "0738-3250", ["PS3 Controller", ""],	; madcats fightpad pro ps3
    "0738-3481", ["PS3 Controller", ""],	; Mad Catz FightStick TE 2+ PS3
    "0738-8180", ["PS3 Controller", ""],	; Mad Catz Alpha PS4 mode (no touchpad on device)
    "0738-8838", ["PS3 Controller", ""],	; Madcatz Fightstick Pro
    "0810-0001", ["PS3 Controller", ""],	; actually ps2 - maybe break out later
    "0810-0003", ["PS3 Controller", ""],	; actually ps2 - maybe break out later
    "0925-0005", ["PS3 Controller", ""],	; Sony PS3 Controller
    "0925-8866", ["PS3 Controller", ""],	; PS2 maybe break out later
    "0925-8888", ["PS3 Controller", ""],	; Actually ps2 -maybe break out later Lakeview Research WiseGroup Ltd, MP-8866 Dual Joypad
    "0e6f-0109", ["PS3 Controller", ""],	; PDP Versus Fighting Pad
    "0e6f-011e", ["PS3 Controller", ""],	; Rock Candy PS4
    "0e6f-0128", ["PS3 Controller", ""],	; Rock Candy PS3
    "0e6f-0214", ["PS3 Controller", ""],	; afterglow ps3
    "0e6f-1314", ["PS3 Controller", ""],	; PDP Afterglow Wireless PS3 controller
    "0e6f-6302", ["PS3 Controller", ""],	; From SDL
    "0e8f-0008", ["PS3 Controller", ""],	; Green Asia
    "0e8f-3075", ["PS3 Controller", ""],	; SpeedLink Strike FX
    "0e8f-310d", ["PS3 Controller", ""],	; From SDL
    "0f0d-0009", ["PS3 Controller", ""],	; HORI BDA GP1
    "0f0d-004d", ["PS3 Controller", ""],	; Horipad 3
    "0f0d-005f", ["PS3 Controller", ""],	; HORI Fighting Commander 4 PS3
    "0f0d-006a", ["PS3 Controller", ""],	; Real Arcade Pro 4
    "0f0d-006e", ["PS3 Controller", ""],	; HORI horipad4 ps3
    "0f0d-0085", ["PS3 Controller", ""],	; HORI Fighting Commander PS3
    "0f0d-0086", ["PS3 Controller", ""],	; HORI Fighting Commander PC (Uses the Xbox 360 protocol, but has PS3 buttons)
    "0f0d-0088", ["PS3 Controller", ""],	; HORI Fighting Stick mini 4
    "0f30-1100", ["PS3 Controller", ""],	; Qanba Q1 fight stick
    "11ff-3331", ["PS3 Controller", ""],	; SRXJ-PH2400
    "1345-1000", ["PS3 Controller", ""],	; PS2 ACME GA-D5
    "1345-6005", ["PS3 Controller", ""],	; ps2 maybe break out later
    "146b-5500", ["PS3 Controller", ""],	; From SDL
    "1a34-0836", ["PS3 Controller", ""],	; Afterglow PS3
    "20bc-5500", ["PS3 Controller", ""],	; ShanWan PS3
    "20d6-576d", ["PS3 Controller", ""],	; Power A PS3
    "20d6-ca6d", ["PS3 Controller", ""],	; BDA Pro Ex
    "2563-0523", ["PS3 Controller", ""],	; Digiflip GP006
    "2563-0575", ["PS3 Controller", ""],	; From SDL
    "25f0-83c3", ["PS3 Controller", ""],	; gioteck vx2
    "25f0-c121", ["PS3 Controller", ""],
    "2c22-2003", ["PS3 Controller", ""],	; Qanba Drone
    "2c22-2302", ["PS3 Controller", ""],	; Qanba Obsidian
    "2c22-2502", ["PS3 Controller", ""],	; Qanba Dragon
    "8380-0003", ["PS3 Controller", ""],	; BTP 2163
    "8888-0308", ["PS3 Controller", ""],	; Sony PS3 Controller
    "0079-181b", ["PS4 Controller", ""],	; Venom Arcade Stick - XXX:this may not work and may need to be called a ps3 controller
    "046d-c260", ["PS4 Controller", ""],	; Logitech G29 (PS4)
    "044f-d00e", ["PS4 Controller", ""],	; Thrustmaster Eswap Pro - No gyro and lightbar doesn't change color. Works otherwise
    "054c-05c4", ["PS4 Controller", ""],	; Sony PS4 Controller
    "054c-05c5", ["PS4 Controller", ""],	; STRIKEPAD PS4 Grip Add-on
    "054c-09cc", ["PS4 Controller", ""],	; Sony PS4 Slim Controller
    "054c-0ba0", ["PS4 Controller", ""],	; Sony PS4 Controller (Wireless dongle)
    "0738-8250", ["PS4 Controller", ""],	; Mad Catz FightPad Pro PS4
    "0738-8384", ["PS4 Controller", ""],	; Mad Catz FightStick TE S+ PS4
    "0738-8480", ["PS4 Controller", ""],	; Mad Catz FightStick TE 2 PS4
    "0738-8481", ["PS4 Controller", ""],	; Mad Catz FightStick TE 2+ PS4
    "0c12-0e10", ["PS4 Controller", ""],	; Armor Armor 3 Pad PS4
    "0c12-0e13", ["PS4 Controller", ""],	; ZEROPLUS P4 Wired Gamepad
    "0c12-0e15", ["PS4 Controller", ""],	; Game:Pad 4
    "0c12-0e20", ["PS4 Controller", ""],	; Brook Mars Controller - needs FW update to show up as Ps4 controller on PC. Has Gyro but touchpad is a single button.
    "0c12-0ef6", ["PS4 Controller", ""],	; Hitbox Arcade Stick
    "0c12-1cf6", ["PS4 Controller", ""],	; EMIO PS4 Elite Controller
    "0c12-1e10", ["PS4 Controller", ""],	; P4 Wired Gamepad generic knock off - lightbar but not trackpad or gyro
    "0e6f-0203", ["PS4 Controller", ""],	; Victrix Pro FS (PS4 peripheral but no trackpad/lightbar)
    "0e6f-0207", ["PS4 Controller", ""],	; Victrix Pro FS V2 w/ Touchpad for PS4
    "0e6f-020a", ["PS4 Controller", ""],	; Victrix Pro FS PS4/PS5 (PS4 mode)
    "0f0d-0055", ["PS4 Controller", ""],	; HORIPAD 4 FPS
    "0f0d-005e", ["PS4 Controller", ""],	; HORI Fighting Commander 4 PS4
    "0f0d-0066", ["PS4 Controller", ""],	; HORIPAD 4 FPS Plus
    "0f0d-0084", ["PS4 Controller", ""],	; HORI Fighting Commander PS4
    "0f0d-0087", ["PS4 Controller", ""],	; HORI Fighting Stick mini 4
    "0f0d-008a", ["PS4 Controller", ""],	; HORI Real Arcade Pro 4
    "0f0d-009c", ["PS4 Controller", ""],	; HORI TAC PRO mousething
    "0f0d-00a0", ["PS4 Controller", ""],	; HORI TAC4 mousething
    "0f0d-00ed", ["PS4 Controller (XInput)", ""],	; Hori Fighting Stick mini 4 kai - becomes an Xbox 360 controller on PC
    "0f0d-00ee", ["PS4 Controller", ""],	; Hori mini wired https:;www.playstation.com/en-us/explore/accessories/gaming-controllers/mini-wired-gamepad/
    "0f0d-011c", ["PS4 Controller", ""],	; Hori Fighting Stick α
    "0f0d-0123", ["PS4 Controller", ""],	; HORI Wireless Controller Light (Japan only) - only over bt- over usb is xbox and pid 0x0124
    "0f0d-0162", ["PS4 Controller", ""],	; HORI Fighting Commander OCTA
    "0f0d-0164", ["PS4 Controller (XInput)", ""],	; HORI Fighting Commander OCTA
    "11c0-4001", ["PS4 Controller", ""],	; "PS4 Fun Controller" added from user log
    "146b-0603", ["PS4 Controller (XInput)", ""],	; Nacon PS4 Compact Controller
    "146b-0604", ["PS4 Controller (XInput)", ""],	; NACON Daija Arcade Stick
    "146b-0605", ["PS4 Controller (XInput)", ""],	; NACON PS4 controller in Xbox mode - might also be other bigben brand xbox controllers
    "146b-0606", ["PS4 Controller (XInput)", ""],	; NACON Unknown Controller
    "146b-0609", ["PS4 Controller (XInput)", ""],	; NACON Wireless Controller for PS4
    "146b-0d01", ["PS4 Controller", ""],	; Nacon Revolution Pro Controller - has gyro
    "146b-0d02", ["PS4 Controller", ""],	; Nacon Revolution Pro Controller v2 - has gyro
    "146b-0d06", ["PS4 Controller", ""],	; NACON Asymmetric Controller Wireless Dongle -- show up as ps4 until you connect controller to it then it reboots into Xbox controller with different vvid/pid
    "146b-0d08", ["PS4 Controller", ""],	; NACON Revolution Unlimited Wireless Dongle
    "146b-0d09", ["PS4 Controller", ""],	; NACON Daija Fight Stick - touchpad but no gyro/rumble
    "146b-0d10", ["PS4 Controller", ""],	; NACON Revolution Infinite - has gyro
    "146b-0d10", ["PS4 Controller", ""],	; NACON Revolution Unlimited
    "146b-0d13", ["PS4 Controller", ""],	; NACON Revolution Pro Controller 3
    "146b-1103", ["PS4 Controller", ""],	; NACON Asymmetric Controller -- on windows this doesn't enumerate
    "1532-0401", ["PS4 Controller", ""],	; Razer Panthera PS4 Controller
    "1532-1000", ["PS4 Controller", ""],	; Razer Raiju PS4 Controller
    "1532-1004", ["PS4 Controller", ""],	; Razer Raiju 2 Ultimate USB
    "1532-1007", ["PS4 Controller", ""],	; Razer Raiju 2 Tournament edition USB
    "1532-1008", ["PS4 Controller", ""],	; Razer Panthera Evo Fightstick
    "1532-1009", ["PS4 Controller", ""],	; Razer Raiju 2 Ultimate BT
    "1532-100A", ["PS4 Controller", ""],	; Razer Raiju 2 Tournament edition BT
    "1532-1100", ["PS4 Controller", ""],	; Razer RAION Fightpad - Trackpad, no gyro, lightbar hardcoded to green
    "20d6-792a", ["PS4 Controller", ""],	; PowerA Fusion Fight Pad
    "2c22-2000", ["PS4 Controller", ""],	; Qanba Drone
    "2c22-2300", ["PS4 Controller", ""],	; Qanba Obsidian
    "2c22-2303", ["PS4 Controller (XInput)", ""],	; Qanba Obsidian Arcade Joystick
    "2c22-2500", ["PS4 Controller", ""],	; Qanba Dragon
    "2c22-2503", ["PS4 Controller (XInput)", ""],	; Qanba Dragon Arcade Joystick
    "3285-0d16", ["PS4 Controller", ""],	; NACON Revolution 5 Pro (PS4 mode with dongle)
    "3285-0d17", ["PS4 Controller", ""],	; NACON Revolution 5 Pro (PS4 mode wired)
    "7545-0104", ["PS4 Controller", ""],	; Armor 3 or Level Up Cobra - At least one variant has gyro
    "9886-0024", ["PS4 Controller (XInput)", ""],  ; Astro C40 in Xbox 360 mode
    "9886-0025", ["PS4 Controller", ""],	; Astro C40
    "7545-1122", ["PS4 Controller", ""],	; Giotek VX4 - trackpad/gyro don't work. Had to not filter on interface info. Light bar is flaky, but works.
    "054c-0ce6", ["PS5 Controller", ""],	; Sony DualSense Controller
    "054c-0df2", ["PS5 Controller", ""],	; Sony DualSense Edge Controller
    "054c-0e5f", ["PS5 Controller", ""],	; Access Controller for PS5
    "0e6f-0209", ["PS5 Controller", ""],	; Victrix Pro FS PS4/PS5 (PS5 mode)
    "0f0d-0163", ["PS5 Controller", ""],	; HORI Fighting Commander OCTA
    "0f0d-0184", ["PS5 Controller", ""],	; Hori Fighting Stick α
    "1532-100b", ["PS5 Controller", ""],	; Razer Wolverine V2 Pro (Wired)
    "1532-100c", ["PS5 Controller", ""],	; Razer Wolverine V2 Pro (Wireless)
    "3285-0d18", ["PS5 Controller", ""],	; NACON Revolution 5 Pro (PS5 mode with dongle)
    "3285-0d19", ["PS5 Controller", ""],	; NACON Revolution 5 Pro (PS5 mode wired)
    "358a-0104", ["PS5 Controller", ""],	; Backbone One PlayStation Edition for iOS
    "0079-0006", ["Steam Controller", ""],	; DragonRise Generic USB PCB, sometimes configured as a PC Twin Shock Controller - looks like a DS3 but the face buttons are 1-4 instead of symbols
    "0079-18d4", ["Xbox 360 Controller", ""],	; GPD Win 2 X-Box Controller
    "03eb-ff02", ["Xbox 360 Controller", ""],	; Wooting Two
    "044f-b326", ["Xbox 360 Controller", ""],	; Thrustmaster Gamepad GP XID
    "045e-028e", ["Xbox 360 Controller", "Xbox 360 Controller"],          ; Microsoft Xbox 360 Wired Controller
    "045e-028f", ["Xbox 360 Controller", "Xbox 360 Controller"],          ; Microsoft Xbox 360 Play and Charge Cable
    "045e-0291", ["Xbox 360 Controller", "Xbox 360 Wireless Controller"], ; X-box 360 Wireless Receiver (third party knockoff)
    "045e-02a0", ["Xbox 360 Controller", ""],                           ; Microsoft Xbox 360 Big Button IR
    "045e-02a1", ["Xbox 360 Controller", "Xbox 360 Wireless Controller"], ; Microsoft Xbox 360 Wireless Controller with XUSB driver on Windows
    "045e-02a9", ["Xbox 360 Controller", "Xbox 360 Wireless Controller"], ; X-box 360 Wireless Receiver (third party knockoff)
    "045e-0719", ["Xbox 360 Controller", "Xbox 360 Wireless Controller"], ; Microsoft Xbox 360 Wireless Receiver
    "046d-c21d", ["Xbox 360 Controller", ""],	; Logitech Gamepad F310
    "046d-c21e", ["Xbox 360 Controller", ""],	; Logitech Gamepad F510
    "046d-c21f", ["Xbox 360 Controller", ""],	; Logitech Gamepad F710
    "046d-c242", ["Xbox 360 Controller", ""],	; Logitech Chillstream Controller
    "056e-2004", ["Xbox 360 Controller", ""],	; Elecom JC-U3613M
    "06a3-f51a", ["Xbox 360 Controller", ""],	; Saitek P3600
    "0738-4716", ["Xbox 360 Controller", ""],	; Mad Catz Wired Xbox 360 Controller
    "0738-4718", ["Xbox 360 Controller", ""],	; Mad Catz Street Fighter IV FightStick SE
    "0738-4726", ["Xbox 360 Controller", ""],	; Mad Catz Xbox 360 Controller
    "0738-4728", ["Xbox 360 Controller", ""],	; Mad Catz Street Fighter IV FightPad
    "0738-4736", ["Xbox 360 Controller", ""],	; Mad Catz MicroCon Gamepad
    "0738-4738", ["Xbox 360 Controller", ""],	; Mad Catz Wired Xbox 360 Controller (SFIV)
    "0738-4740", ["Xbox 360 Controller", ""],	; Mad Catz Beat Pad
    "0738-b726", ["Xbox 360 Controller", ""],	; Mad Catz Xbox controller - MW2
    "0738-beef", ["Xbox 360 Controller", ""],	; Mad Catz JOYTECH NEO SE Advanced GamePad
    "0738-cb02", ["Xbox 360 Controller", ""],	; Saitek Cyborg Rumble Pad - PC/Xbox 360
    "0738-cb03", ["Xbox 360 Controller", ""],	; Saitek P3200 Rumble Pad - PC/Xbox 360
    "0738-f738", ["Xbox 360 Controller", ""],	; Super SFIV FightStick TE S
    "0955-7210", ["Xbox 360 Controller", ""],	; Nvidia Shield local controller
    "0955-b400", ["Xbox 360 Controller", ""],	; NVIDIA Shield streaming controller
    "0e6f-0105", ["Xbox 360 Controller", ""],	; HSM3 Xbox360 dancepad
    "0e6f-0113", ["Xbox 360 Controller", "PDP Xbox 360 Afterglow"],	; PDP Afterglow Gamepad for Xbox 360
    "0e6f-011f", ["Xbox 360 Controller", "PDP Xbox 360 Rock Candy"],	; PDP Rock Candy Gamepad for Xbox 360
    "0e6f-0125", ["Xbox 360 Controller", "PDP INJUSTICE FightStick"],	; PDP INJUSTICE FightStick for Xbox 360
    "0e6f-0127", ["Xbox 360 Controller", "PDP INJUSTICE FightPad"],	; PDP INJUSTICE FightPad for Xbox 360
    "0e6f-0131", ["Xbox 360 Controller", "PDP EA Soccer Controller"],	; PDP EA Soccer Gamepad
    "0e6f-0133", ["Xbox 360 Controller", "PDP Battlefield 4 Controller"],	; PDP Battlefield 4 Gamepad
    "0e6f-0143", ["Xbox 360 Controller", "PDP MK X Fight Stick"],	; PDP MK X Fight Stick for Xbox 360
    "0e6f-0147", ["Xbox 360 Controller", "PDP Xbox 360 Marvel Controller"],	; PDP Marvel Controller for Xbox 360
    "0e6f-0201", ["Xbox 360 Controller", "PDP Xbox 360 Controller"],	; PDP Gamepad for Xbox 360
    "0e6f-0213", ["Xbox 360 Controller", "PDP Xbox 360 Afterglow"],	; PDP Afterglow Gamepad for Xbox 360
    "0e6f-021f", ["Xbox 360 Controller", "PDP Xbox 360 Rock Candy"],	; PDP Rock Candy Gamepad for Xbox 360
    "0e6f-0301", ["Xbox 360 Controller", "PDP Xbox 360 Controller"],	; PDP Gamepad for Xbox 360
    "0e6f-0313", ["Xbox 360 Controller", "PDP Xbox 360 Afterglow"],	; PDP Afterglow Gamepad for Xbox 360
    "0e6f-0314", ["Xbox 360 Controller", "PDP Xbox 360 Afterglow"],	; PDP Afterglow Gamepad for Xbox 360
    "0e6f-0401", ["Xbox 360 Controller", "PDP Xbox 360 Controller"],	; PDP Gamepad for Xbox 360
    "0e6f-0413", ["Xbox 360 Controller", ""],	; PDP Afterglow AX.1 (unlisted)
    "0e6f-0501", ["Xbox 360 Controller", ""],	; PDP Xbox 360 Controller (unlisted)
    "0e6f-f900", ["Xbox 360 Controller", ""],	; PDP Afterglow AX.1 (unlisted)
    "0f0d-000a", ["Xbox 360 Controller", ""],	; Hori Co. DOA4 FightStick
    "0f0d-000c", ["Xbox 360 Controller", ""],	; Hori PadEX Turbo
    "0f0d-000d", ["Xbox 360 Controller", ""],	; Hori Fighting Stick EX2
    "0f0d-0016", ["Xbox 360 Controller", ""],	; Hori Real Arcade Pro.EX
    "0f0d-001b", ["Xbox 360 Controller", ""],	; Hori Real Arcade Pro VX
    "0f0d-008c", ["Xbox 360 Controller", ""],	; Hori Real Arcade Pro 4
    "0f0d-00db", ["Xbox 360 Controller", "HORI Slime Controller"],	; Hori Dragon Quest Slime Controller
    "0f0d-011e", ["Xbox 360 Controller", ""],	; Hori Fighting Stick α
    "1038-1430", ["Xbox 360 Controller", "SteelSeries Stratus Duo"],	; SteelSeries Stratus Duo
    "1038-1431", ["Xbox 360 Controller", "SteelSeries Stratus Duo"],	; SteelSeries Stratus Duo
    "1038-b360", ["Xbox 360 Controller", ""],	; SteelSeries Nimbus/Stratus XL
    "11c9-55f0", ["Xbox 360 Controller", ""],	; Nacon GC-100XF
    "12ab-0004", ["Xbox 360 Controller", ""],	; Honey Bee Xbox360 dancepad
    "12ab-0301", ["Xbox 360 Controller", ""],	; PDP AFTERGLOW AX.1
    "12ab-0303", ["Xbox 360 Controller", ""],	; Mortal Kombat Klassic FightStick
    "1430-02a0", ["Xbox 360 Controller", ""],	; RedOctane Controller Adapter
    "1430-4748", ["Xbox 360 Controller", ""],	; RedOctane Guitar Hero X-plorer
    "1430-f801", ["Xbox 360 Controller", ""],	; RedOctane Controller
    "146b-0601", ["Xbox 360 Controller", ""],	; BigBen Interactive XBOX 360 Controller
    "1532-0037", ["Xbox 360 Controller", ""],	; Razer Sabertooth
    "15e4-3f00", ["Xbox 360 Controller", ""],	; Power A Mini Pro Elite
    "15e4-3f0a", ["Xbox 360 Controller", ""],	; Xbox Airflo wired controller
    "15e4-3f10", ["Xbox 360 Controller", ""],	; Batarang Xbox 360 controller
    "162e-beef", ["Xbox 360 Controller", ""],	; Joytech Neo-Se Take2
    "1689-fd00", ["Xbox 360 Controller", ""],	; Razer Onza Tournament Edition
    "1689-fd01", ["Xbox 360 Controller", ""],	; Razer Onza Classic Edition
    "1689-fe00", ["Xbox 360 Controller", ""],	; Razer Sabertooth
    "1949-041a", ["Xbox 360 Controller", "Amazon Luna Controller"],	; Amazon Luna Controller
    "1bad-0002", ["Xbox 360 Controller", ""],	; Harmonix Rock Band Guitar
    "1bad-0003", ["Xbox 360 Controller", ""],	; Harmonix Rock Band Drumkit
    "1bad-f016", ["Xbox 360 Controller", ""],	; Mad Catz Xbox 360 Controller
    "1bad-f018", ["Xbox 360 Controller", ""],	; Mad Catz Street Fighter IV SE Fighting Stick
    "1bad-f019", ["Xbox 360 Controller", ""],	; Mad Catz Brawlstick for Xbox 360
    "1bad-f021", ["Xbox 360 Controller", ""],	; Mad Cats Ghost Recon FS GamePad
    "1bad-f023", ["Xbox 360 Controller", ""],	; MLG Pro Circuit Controller (Xbox)
    "1bad-f025", ["Xbox 360 Controller", ""],	; Mad Catz Call Of Duty
    "1bad-f027", ["Xbox 360 Controller", ""],	; Mad Catz FPS Pro
    "1bad-f028", ["Xbox 360 Controller", ""],	; Street Fighter IV FightPad
    "1bad-f02e", ["Xbox 360 Controller", ""],	; Mad Catz Fightpad
    "1bad-f036", ["Xbox 360 Controller", ""],	; Mad Catz MicroCon GamePad Pro
    "1bad-f038", ["Xbox 360 Controller", ""],	; Street Fighter IV FightStick TE
    "1bad-f039", ["Xbox 360 Controller", ""],	; Mad Catz MvC2 TE
    "1bad-f03a", ["Xbox 360 Controller", ""],	; Mad Catz SFxT Fightstick Pro
    "1bad-f03d", ["Xbox 360 Controller", ""],	; Street Fighter IV Arcade Stick TE - Chun Li
    "1bad-f03e", ["Xbox 360 Controller", ""],	; Mad Catz MLG FightStick TE
    "1bad-f03f", ["Xbox 360 Controller", ""],	; Mad Catz FightStick SoulCaliber
    "1bad-f042", ["Xbox 360 Controller", ""],	; Mad Catz FightStick TES+
    "1bad-f080", ["Xbox 360 Controller", ""],	; Mad Catz FightStick TE2
    "1bad-f501", ["Xbox 360 Controller", ""],	; HoriPad EX2 Turbo
    "1bad-f502", ["Xbox 360 Controller", ""],	; Hori Real Arcade Pro.VX SA
    "1bad-f503", ["Xbox 360 Controller", ""],	; Hori Fighting Stick VX
    "1bad-f504", ["Xbox 360 Controller", ""],	; Hori Real Arcade Pro. EX
    "1bad-f505", ["Xbox 360 Controller", ""],	; Hori Fighting Stick EX2B
    "1bad-f506", ["Xbox 360 Controller", ""],	; Hori Real Arcade Pro.EX Premium VLX
    "1bad-f900", ["Xbox 360 Controller", ""],	; Harmonix Xbox 360 Controller
    "1bad-f901", ["Xbox 360 Controller", ""],	; Gamestop Xbox 360 Controller
    "1bad-f902", ["Xbox 360 Controller", ""],	; Mad Catz Gamepad2
    "1bad-f903", ["Xbox 360 Controller", ""],	; Tron Xbox 360 controller
    "1bad-f904", ["Xbox 360 Controller", ""],	; PDP Versus Fighting Pad
    "1bad-f906", ["Xbox 360 Controller", ""],	; MortalKombat FightStick
    "1bad-fa01", ["Xbox 360 Controller", ""],	; MadCatz GamePad
    "1bad-fd00", ["Xbox 360 Controller", ""],	; Razer Onza TE
    "1bad-fd01", ["Xbox 360 Controller", ""],	; Razer Onza
    "24c6-5000", ["Xbox 360 Controller", ""],	; Razer Atrox Arcade Stick
    "24c6-5300", ["Xbox 360 Controller", ""],	; PowerA MINI PROEX Controller
    "24c6-5303", ["Xbox 360 Controller", ""],	; Xbox Airflo wired controller
    "24c6-530a", ["Xbox 360 Controller", ""],	; Xbox 360 Pro EX Controller
    "24c6-531a", ["Xbox 360 Controller", ""],	; PowerA Pro Ex
    "24c6-5397", ["Xbox 360 Controller", ""],	; FUS1ON Tournament Controller
    "24c6-5500", ["Xbox 360 Controller", ""],	; Hori XBOX 360 EX 2 with Turbo
    "24c6-5501", ["Xbox 360 Controller", ""],	; Hori Real Arcade Pro VX-SA
    "24c6-5502", ["Xbox 360 Controller", ""],	; Hori Fighting Stick VX Alt
    "24c6-5503", ["Xbox 360 Controller", ""],	; Hori Fighting Edge
    "24c6-5506", ["Xbox 360 Controller", ""],	; Hori SOULCALIBUR V Stick
    "24c6-550d", ["Xbox 360 Controller", ""],	; Hori GEM Xbox controller
    "24c6-550e", ["Xbox 360 Controller", ""],	; Hori Real Arcade Pro V Kai 360
    "24c6-5508", ["Xbox 360 Controller", ""],	; Hori PAD A
    "24c6-5510", ["Xbox 360 Controller", ""],	; Hori Fighting Commander ONE
    "24c6-5b00", ["Xbox 360 Controller", ""],	; ThrustMaster Ferrari Italia 458 Racing Wheel
    "24c6-5b02", ["Xbox 360 Controller", ""],	; Thrustmaster, Inc. GPX Controller
    "24c6-5b03", ["Xbox 360 Controller", ""],	; Thrustmaster Ferrari 458 Racing Wheel
    "24c6-5d04", ["Xbox 360 Controller", ""],	; Razer Sabertooth
    "24c6-fafa", ["Xbox 360 Controller", ""],	; Aplay Controller
    "24c6-fafb", ["Xbox 360 Controller", ""],	; Aplay Controller
    "24c6-fafc", ["Xbox 360 Controller", ""],	; Afterglow Gamepad 1
    "24c6-fafd", ["Xbox 360 Controller", ""],	; Afterglow Gamepad 3
    "24c6-fafe", ["Xbox 360 Controller", ""],	; Rock Candy Gamepad for Xbox 360
    "03f0-0495", ["Xbox One Controller", ""],	; HP HyperX Clutch Gladiate
    "044f-d012", ["Xbox One Controller", ""],	; ThrustMaster eSwap PRO Controller Xbox
    "045e-02d1", ["Xbox One Controller", "Xbox One Controller"],         ; Microsoft Xbox One Controller
    "045e-02dd", ["Xbox One Controller", "Xbox One Controller"],         ; Microsoft Xbox One Controller (Firmware 2015)
    "045e-02e0", ["Xbox One Controller", "Xbox One S Controller"],       ; Microsoft Xbox One S Controller (Bluetooth)
    "045e-02e3", ["Xbox One Controller", "Xbox One Elite Controller"],   ; Microsoft Xbox One Elite Controller
    "045e-02ea", ["Xbox One Controller", "Xbox One S Controller"],       ; Microsoft Xbox One S Controller
    "045e-02fd", ["Xbox One Controller", "Xbox One S Controller"],       ; Microsoft Xbox One S Controller (Bluetooth)
    "045e-02ff", ["Xbox One Controller", "Xbox One Controller"],         ; Microsoft Xbox One Controller with XBOXGIP driver on Windows
    "045e-0b00", ["Xbox One Controller", "Xbox One Elite 2 Controller"], ; Microsoft Xbox One Elite Series 2 Controller
    "045e-0b05", ["Xbox One Controller", "Xbox One Elite 2 Controller"], ; Microsoft Xbox One Elite Series 2 Controller (Bluetooth)
    "045e-0b0a", ["Xbox One Controller", "Xbox Adaptive Controller"],    ; Microsoft Xbox Adaptive Controller
    "045e-0b0c", ["Xbox One Controller", "Xbox Adaptive Controller"],    ; Microsoft Xbox Adaptive Controller (Bluetooth)
    "045e-0b12", ["Xbox One Controller", "Xbox Series X Controller"],    ; Microsoft Xbox Series X Controller
    "045e-0b13", ["Xbox One Controller", "Xbox Series X Controller"],    ; Microsoft Xbox Series X Controller (BLE)
    "045e-0b20", ["Xbox One Controller", "Xbox One S Controller"],       ; Microsoft Xbox One S Controller (BLE)
    "045e-0b21", ["Xbox One Controller", "Xbox Adaptive Controller"],    ; Microsoft Xbox Adaptive Controller (BLE)
    "045e-0b22", ["Xbox One Controller", "Xbox One Elite 2 Controller"], ; Microsoft Xbox One Elite Series 2 Controller (BLE)
    "0738-4a01", ["Xbox One Controller", ""],	; Mad Catz FightStick TE 2
    "0e6f-0139", ["Xbox One Controller", "PDP Xbox One Afterglow"],	; PDP Afterglow Wired Controller for Xbox One
    "0e6f-013B", ["Xbox One Controller", "PDP Xbox One Face-Off Controller"],	; PDP Face-Off Gamepad for Xbox One
    "0e6f-013a", ["Xbox One Controller", ""],	; PDP Xbox One Controller (unlisted)
    "0e6f-0145", ["Xbox One Controller", "PDP MK X Fight Pad"],	; PDP MK X Fight Pad for Xbox One
    "0e6f-0146", ["Xbox One Controller", "PDP Xbox One Rock Candy"],	; PDP Rock Candy Wired Controller for Xbox One
    "0e6f-015b", ["Xbox One Controller", "PDP Fallout 4 Vault Boy Controller"],	; PDP Fallout 4 Vault Boy Wired Controller for Xbox One
    "0e6f-015c", ["Xbox One Controller", "PDP Xbox One @Play Controller"],	; PDP @Play Wired Controller for Xbox One
    "0e6f-015d", ["Xbox One Controller", "PDP Mirror's Edge Controller"],	; PDP Mirror's Edge Wired Controller for Xbox One
    "0e6f-015f", ["Xbox One Controller", "PDP Metallic Controller"],	; PDP Metallic Wired Controller for Xbox One
    "0e6f-0160", ["Xbox One Controller", "PDP NFL Face-Off Controller"],	; PDP NFL Official Face-Off Wired Controller for Xbox One
    "0e6f-0161", ["Xbox One Controller", "PDP Xbox One Camo"],	; PDP Camo Wired Controller for Xbox One
    "0e6f-0162", ["Xbox One Controller", "PDP Xbox One Controller"],	; PDP Wired Controller for Xbox One
    "0e6f-0163", ["Xbox One Controller", "PDP Deliverer of Truth"],	; PDP Legendary Collection: Deliverer of Truth
    "0e6f-0164", ["Xbox One Controller", "PDP Battlefield 1 Controller"],	; PDP Battlefield 1 Official Wired Controller for Xbox One
    "0e6f-0165", ["Xbox One Controller", "PDP Titanfall 2 Controller"],	; PDP Titanfall 2 Official Wired Controller for Xbox One
    "0e6f-0166", ["Xbox One Controller", "PDP Mass Effect: Andromeda Controller"],	; PDP Mass Effect: Andromeda Official Wired Controller for Xbox One
    "0e6f-0167", ["Xbox One Controller", "PDP Halo Wars 2 Face-Off Controller"],	; PDP Halo Wars 2 Official Face-Off Wired Controller for Xbox One
    "0e6f-0205", ["Xbox One Controller", "PDP Victrix Pro Fight Stick"],	; PDP Victrix Pro Fight Stick
    "0e6f-0206", ["Xbox One Controller", "PDP Mortal Kombat Controller"],	; PDP Mortal Kombat 25 Anniversary Edition Stick (Xbox One)
    "0e6f-0246", ["Xbox One Controller", "PDP Xbox One Rock Candy"],	; PDP Rock Candy Wired Controller for Xbox One
    "0e6f-0261", ["Xbox One Controller", "PDP Xbox One Camo"],	; PDP Camo Wired Controller
    "0e6f-0262", ["Xbox One Controller", "PDP Xbox One Controller"],	; PDP Wired Controller
    "0e6f-02a0", ["Xbox One Controller", "PDP Xbox One Midnight Blue"],	; PDP Wired Controller for Xbox One - Midnight Blue
    "0e6f-02a1", ["Xbox One Controller", "PDP Xbox One Verdant Green"],	; PDP Wired Controller for Xbox One - Verdant Green
    "0e6f-02a2", ["Xbox One Controller", "PDP Xbox One Crimson Red"],	; PDP Wired Controller for Xbox One - Crimson Red
    "0e6f-02a3", ["Xbox One Controller", "PDP Xbox One Arctic White"],	; PDP Wired Controller for Xbox One - Arctic White
    "0e6f-02a4", ["Xbox One Controller", "PDP Xbox One Phantom Black"],	; PDP Wired Controller for Xbox One - Stealth Series | Phantom Black
    "0e6f-02a5", ["Xbox One Controller", "PDP Xbox One Ghost White"],	; PDP Wired Controller for Xbox One - Stealth Series | Ghost White
    "0e6f-02a6", ["Xbox One Controller", "PDP Xbox One Revenant Blue"],	; PDP Wired Controller for Xbox One - Stealth Series | Revenant Blue
    "0e6f-02a7", ["Xbox One Controller", "PDP Xbox One Raven Black"],	; PDP Wired Controller for Xbox One - Raven Black
    "0e6f-02a8", ["Xbox One Controller", "PDP Xbox One Arctic White"],	; PDP Wired Controller for Xbox One - Arctic White
    "0e6f-02a9", ["Xbox One Controller", "PDP Xbox One Midnight Blue"],	; PDP Wired Controller for Xbox One - Midnight Blue
    "0e6f-02aa", ["Xbox One Controller", "PDP Xbox One Verdant Green"],	; PDP Wired Controller for Xbox One - Verdant Green
    "0e6f-02ab", ["Xbox One Controller", "PDP Xbox One Crimson Red"],	; PDP Wired Controller for Xbox One - Crimson Red
    "0e6f-02ac", ["Xbox One Controller", "PDP Xbox One Ember Orange"],	; PDP Wired Controller for Xbox One - Ember Orange
    "0e6f-02ad", ["Xbox One Controller", "PDP Xbox One Phantom Black"],	; PDP Wired Controller for Xbox One - Stealth Series | Phantom Black
    "0e6f-02ae", ["Xbox One Controller", "PDP Xbox One Ghost White"],	; PDP Wired Controller for Xbox One - Stealth Series | Ghost White
    "0e6f-02af", ["Xbox One Controller", "PDP Xbox One Revenant Blue"],	; PDP Wired Controller for Xbox One - Stealth Series | Revenant Blue
    "0e6f-02b0", ["Xbox One Controller", "PDP Xbox One Raven Black"],	; PDP Wired Controller for Xbox One - Raven Black
    "0e6f-02b1", ["Xbox One Controller", "PDP Xbox One Arctic White"],	; PDP Wired Controller for Xbox One - Arctic White
    "0e6f-02b3", ["Xbox One Controller", "PDP Xbox One Afterglow"],	; PDP Afterglow Prismatic Wired Controller
    "0e6f-02b5", ["Xbox One Controller", "PDP Xbox One GAMEware Controller"],	; PDP GAMEware Wired Controller Xbox One
    "0e6f-02b6", ["Xbox One Controller", ""],	; PDP One-Handed Joystick Adaptive Controller
    "0e6f-02bd", ["Xbox One Controller", "PDP Xbox One Royal Purple"],	; PDP Wired Controller for Xbox One - Royal Purple
    "0e6f-02be", ["Xbox One Controller", "PDP Xbox One Raven Black"],	; PDP Deluxe Wired Controller for Xbox One - Raven Black
    "0e6f-02bf", ["Xbox One Controller", "PDP Xbox One Midnight Blue"],	; PDP Deluxe Wired Controller for Xbox One - Midnight Blue
    "0e6f-02c0", ["Xbox One Controller", "PDP Xbox One Phantom Black"],	; PDP Deluxe Wired Controller for Xbox One - Stealth Series | Phantom Black
    "0e6f-02c1", ["Xbox One Controller", "PDP Xbox One Ghost White"],	; PDP Deluxe Wired Controller for Xbox One - Stealth Series | Ghost White
    "0e6f-02c2", ["Xbox One Controller", "PDP Xbox One Revenant Blue"],	; PDP Deluxe Wired Controller for Xbox One - Stealth Series | Revenant Blue
    "0e6f-02c3", ["Xbox One Controller", "PDP Xbox One Verdant Green"],	; PDP Deluxe Wired Controller for Xbox One - Verdant Green
    "0e6f-02c4", ["Xbox One Controller", "PDP Xbox One Ember Orange"],	; PDP Deluxe Wired Controller for Xbox One - Ember Orange
    "0e6f-02c5", ["Xbox One Controller", "PDP Xbox One Royal Purple"],	; PDP Deluxe Wired Controller for Xbox One - Royal Purple
    "0e6f-02c6", ["Xbox One Controller", "PDP Xbox One Crimson Red"],	; PDP Deluxe Wired Controller for Xbox One - Crimson Red
    "0e6f-02c7", ["Xbox One Controller", "PDP Xbox One Arctic White"],	; PDP Deluxe Wired Controller for Xbox One - Arctic White
    "0e6f-02c8", ["Xbox One Controller", "PDP Kingdom Hearts Controller"],	; PDP Kingdom Hearts Wired Controller
    "0e6f-02c9", ["Xbox One Controller", "PDP Xbox One Phantasm Red"],	; PDP Deluxe Wired Controller for Xbox One - Stealth Series | Phantasm Red
    "0e6f-02ca", ["Xbox One Controller", "PDP Xbox One Specter Violet"],	; PDP Deluxe Wired Controller for Xbox One - Stealth Series | Specter Violet
    "0e6f-02cb", ["Xbox One Controller", "PDP Xbox One Specter Violet"],	; PDP Wired Controller for Xbox One - Stealth Series | Specter Violet
    "0e6f-02cd", ["Xbox One Controller", "PDP Xbox One Blu-merang"],	; PDP Rock Candy Wired Controller for Xbox One - Blu-merang
    "0e6f-02ce", ["Xbox One Controller", "PDP Xbox One Cranblast"],	; PDP Rock Candy Wired Controller for Xbox One - Cranblast
    "0e6f-02cf", ["Xbox One Controller", "PDP Xbox One Aqualime"],	; PDP Rock Candy Wired Controller for Xbox One - Aqualime
    "0e6f-02d5", ["Xbox One Controller", "PDP Xbox One Red Camo"],	; PDP Wired Controller for Xbox One - Red Camo
    "0e6f-0346", ["Xbox One Controller", "PDP Xbox One RC Gamepad"],	; PDP RC Gamepad for Xbox One
    "0e6f-0446", ["Xbox One Controller", "PDP Xbox One RC Gamepad"],	; PDP RC Gamepad for Xbox One
    "0e6f-02da", ["Xbox One Controller", "PDP Xbox Series X Afterglow"],	; PDP Xbox Series X Afterglow
    "0e6f-02d6", ["Xbox One Controller", "Victrix Gambit Tournament Controller"],	; Victrix Gambit Tournament Controller
    "0e6f-02d9", ["Xbox One Controller", "PDP Xbox Series X Midnight Blue"],	; PDP Xbox Series X Midnight Blue
    "0f0d-0063", ["Xbox One Controller", ""],	; Hori Real Arcade Pro Hayabusa (USA) Xbox One
    "0f0d-0067", ["Xbox One Controller", ""],	; HORIPAD ONE
    "0f0d-0078", ["Xbox One Controller", ""],	; Hori Real Arcade Pro V Kai Xbox One
    "0f0d-00c5", ["Xbox One Controller", ""],	; HORI Fighting Commander
    "0f0d-0150", ["Xbox One Controller", ""],	; HORI Fighting Commander OCTA for Xbox Series X
    "10f5-7009", ["Xbox One Controller", ""],	; Turtle Beach Recon Controller
    "10f5-7013", ["Xbox One Controller", ""],	; Turtle Beach REACT-R
    "1532-0a00", ["Xbox One Controller", ""],	; Razer Atrox Arcade Stick
    "1532-0a03", ["Xbox One Controller", ""],	; Razer Wildcat
    "1532-0a14", ["Xbox One Controller", ""],	; Razer Wolverine Ultimate
    "1532-0a15", ["Xbox One Controller", ""],	; Razer Wolverine Tournament Edition
    "20d6-2001", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Controller - Black Inline
    "20d6-2002", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Controller Gray/White Inline
    "20d6-2003", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Controller Green Inline
    "20d6-2004", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Controller Pink inline
    "20d6-2005", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X Wired Controller Core - Black
    "20d6-2006", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X Wired Controller Core - White
    "20d6-2009", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Controller Red inline
    "20d6-200a", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Controller Blue inline
    "20d6-200b", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Controller Camo Metallic Red
    "20d6-200c", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Controller Camo Metallic Blue
    "20d6-200d", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Controller Seafoam Fade
    "20d6-200e", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Controller Midnight Blue
    "20d6-200f", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Soldier Green
    "20d6-2011", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired - Metallic Ice
    "20d6-2012", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X Cuphead EnWired Controller - Mugman
    "20d6-2015", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Controller - Blue Hint
    "20d6-2016", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Controller - Green Hint
    "20d6-2017", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Cntroller - Arctic Camo
    "20d6-2018", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Controller Arc Lightning
    "20d6-2019", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Controller Royal Purple
    "20d6-201a", ["Xbox One Controller", "PowerA Xbox Series X Controller"],       ; PowerA Xbox Series X EnWired Controller Nebula
    "20d6-4001", ["Xbox One Controller", "PowerA Fusion Pro 2 Controller"],	; PowerA Fusion Pro 2 Wired Controller (Xbox Series X style)
    "20d6-4002", ["Xbox One Controller", "PowerA Spectra Infinity Controller"],	; PowerA Spectra Infinity Wired Controller (Xbox Series X style)
    "20d6-890b", ["Xbox One Controller", ""],	; PowerA MOGA XP-Ultra Controller (Xbox Series X style)
    "24c6-541a", ["Xbox One Controller", ""],	; PowerA Xbox One Mini Wired Controller
    "24c6-542a", ["Xbox One Controller", ""],	; Xbox ONE spectra
    "24c6-543a", ["Xbox One Controller", "PowerA Xbox One Controller"],	; PowerA Xbox ONE liquid metal controller
    "24c6-551a", ["Xbox One Controller", ""],	; PowerA FUSION Pro Controller
    "24c6-561a", ["Xbox One Controller", ""],	; PowerA FUSION Controller
    "24c6-581a", ["Xbox One Controller", ""],	; BDA XB1 Classic Controller
    "24c6-591a", ["Xbox One Controller", ""],	; PowerA FUSION Pro Controller
    "24c6-592a", ["Xbox One Controller", ""],	; BDA XB1 Spectra Pro
    "24c6-791a", ["Xbox One Controller", ""],	; PowerA Fusion Fight Pad
    "2dc8-2002", ["Xbox One Controller", ""],	; 8BitDo Ultimate Wired Controller for Xbox
    "2e24-0652", ["Xbox One Controller", ""],	; Hyperkin Duke
    "2e24-1618", ["Xbox One Controller", ""],	; Hyperkin Duke
    "2e24-1688", ["Xbox One Controller", ""],	; Hyperkin X91
    "146b-0611", ["Xbox One Controller", ""],	; Xbox Controller Mode for NACON Revolution 3
    "0000-0000", ["Xbox 360 Controller", ""],	; Unknown Controller
    "045e-02a2", ["Xbox 360 Controller", ""],	; Unknown Controller - Microsoft VID
    "0e6f-1414", ["Xbox 360 Controller", ""],	; Unknown Controller
    "0e6f-0159", ["Xbox 360 Controller", ""],	; Unknown Controller
    "24c6-faff", ["Xbox 360 Controller", ""],	; Unknown Controller
    "0f0d-006d", ["Xbox 360 Controller", ""],	; Unknown Controller
    "0f0d-00a4", ["Xbox 360 Controller", ""],	; Unknown Controller
    "0079-1832", ["Xbox 360 Controller", ""],	; Unknown Controller
    "0079-187f", ["Xbox 360 Controller", ""],	; Unknown Controller
    "0079-1883", ["Xbox 360 Controller", ""],	; Unknown Controller
    "03eb-ff01", ["Xbox 360 Controller", ""],	; Unknown Controller
    "0c12-0ef8", ["Xbox 360 Controller", ""],	; Homemade fightstick based on brook pcb (with XInput driver??)
    "046d-1000", ["Xbox 360 Controller", ""],	; Unknown Controller
    "1345-6006", ["Xbox 360 Controller", ""],	; Unknown Controller
    "056e-2012", ["Xbox 360 Controller", ""],	; Unknown Controller
    "146b-0602", ["Xbox 360 Controller", ""],	; Unknown Controller
    "0f0d-00ae", ["Xbox 360 Controller", ""],	; Unknown Controller
    "046d-0401", ["Xbox 360 Controller", ""],	; logitech xinput
    "046d-0301", ["Xbox 360 Controller", ""],	; logitech xinput
    "046d-caa3", ["Xbox 360 Controller", ""],	; logitech xinput
    "046d-c261", ["Xbox 360 Controller", ""],	; logitech xinput
    "046d-0291", ["Xbox 360 Controller", ""],	; logitech xinput
    "0079-18d3", ["Xbox 360 Controller", ""],	; Unknown Controller
    "0f0d-00b1", ["Xbox 360 Controller", ""],	; Unknown Controller
    "0001-0001", ["Xbox 360 Controller", ""],	; Unknown Controller
    "0079-188e", ["Xbox 360 Controller", ""],	; Unknown Controller
    "0079-187c", ["Xbox 360 Controller", ""],	; Unknown Controller
    "0079-189c", ["Xbox 360 Controller", ""],	; Unknown Controller
    "0079-1874", ["Xbox 360 Controller", ""],	; Unknown Controller
    "2f24-0050", ["Xbox One Controller", ""],	; Unknown Controller
    "2f24-002e", ["Xbox One Controller", ""],	; Unknown Controller
    "2f24-0091", ["Xbox One Controller", ""],	; Unknown Controller
    "1430-0719", ["Xbox One Controller", ""],	; Unknown Controller
    "0f0d-00ed", ["Xbox One Controller", ""],	; Unknown Controller
    "0f0d-00c0", ["Xbox One Controller", ""],	; Unknown Controller
    "0e6f-0152", ["Xbox One Controller", ""],	; Unknown Controller
    "0e6f-02a7", ["Xbox One Controller", ""],	; Unknown Controller
    "046d-1007", ["Xbox One Controller", ""],	; Unknown Controller
    "0e6f-02b8", ["Xbox One Controller", ""],	; Unknown Controller
    "0e6f-02a8", ["Xbox One Controller", ""],	; Unknown Controller
    "0079-18a1", ["Xbox One Controller", ""],	; Unknown Controller
    "0000-6686", ["Xbox One Controller", ""],	; Unknown Controller
    "11ff-0511", ["Xbox One Controller", ""],	; Unknown Controller
    "12ab-0304", ["Xbox One Controller", ""],	; Unknown Controller
    "1430-0291", ["Xbox One Controller", ""],	; Unknown Controller
    "1430-02a9", ["Xbox One Controller", ""],	; Unknown Controller
    "1430-070b", ["Xbox One Controller", ""],	; Unknown Controller
    "1bad-028e", ["Xbox One Controller", ""],	; Unknown Controller
    "1bad-02a0", ["Xbox One Controller", ""],	; Unknown Controller
    "1bad-5500", ["Xbox One Controller", ""],	; Unknown Controller
    "20ab-55ef", ["Xbox One Controller", ""],	; Unknown Controller
    "24c6-5509", ["Xbox One Controller", ""],	; Unknown Controller
    "2516-0069", ["Xbox One Controller", ""],	; Unknown Controller
    "25b1-0360", ["Xbox One Controller", ""],	; Unknown Controller
    "2c22-2203", ["Xbox One Controller", ""],	; Unknown Controller
    "2f24-0011", ["Xbox One Controller", ""],	; Unknown Controller
    "2f24-0053", ["Xbox One Controller", ""],	; Unknown Controller
    "2f24-00b7", ["Xbox One Controller", ""],	; Unknown Controller
    "046d-0000", ["Xbox One Controller", ""],	; Unknown Controller
    "046d-1004", ["Xbox One Controller", ""],	; Unknown Controller
    "046d-1008", ["Xbox One Controller", ""],	; Unknown Controller
    "046d-f301", ["Xbox One Controller", ""],	; Unknown Controller
    "0738-02a0", ["Xbox One Controller", ""],	; Unknown Controller
    "0738-7263", ["Xbox One Controller", ""],	; Unknown Controller
    "0738-b738", ["Xbox One Controller", ""],	; Unknown Controller
    "0738-cb29", ["Xbox One Controller", ""],	; Unknown Controller
    "0738-f401", ["Xbox One Controller", ""],	; Unknown Controller
    "0079-18c2", ["Xbox One Controller", ""],	; Unknown Controller
    "0079-18c8", ["Xbox One Controller", ""],	; Unknown Controller
    "0079-18cf", ["Xbox One Controller", ""],	; Unknown Controller
    "0c12-0e17", ["Xbox One Controller", ""],	; Unknown Controller
    "0c12-0e1c", ["Xbox One Controller", ""],	; Unknown Controller
    "0c12-0e22", ["Xbox One Controller", ""],	; Unknown Controller
    "0c12-0e30", ["Xbox One Controller", ""],	; Unknown Controller
    "d2d2-d2d2", ["Xbox One Controller", ""],	; Unknown Controller
    "0d62-9a1a", ["Xbox One Controller", ""],	; Unknown Controller
    "0d62-9a1b", ["Xbox One Controller", ""],	; Unknown Controller
    "0e00-0e00", ["Xbox One Controller", ""],	; Unknown Controller
    "0e6f-012a", ["Xbox One Controller", ""],	; Unknown Controller
    "0e6f-02a1", ["Xbox One Controller", ""],	; Unknown Controller
    "0e6f-02a2", ["Xbox One Controller", ""],	; Unknown Controller
    "0e6f-02a5", ["Xbox One Controller", ""],	; Unknown Controller
    "0e6f-02b2", ["Xbox One Controller", ""],	; Unknown Controller
    "0e6f-02bd", ["Xbox One Controller", ""],	; Unknown Controller
    "0e6f-02bf", ["Xbox One Controller", ""],	; Unknown Controller
    "0e6f-02c0", ["Xbox One Controller", ""],	; Unknown Controller
    "0e6f-02c6", ["Xbox One Controller", ""],	; Unknown Controller
    "0f0d-0097", ["Xbox One Controller", ""],	; Unknown Controller
    "0f0d-00ba", ["Xbox One Controller", ""],	; Unknown Controller
    "0f0d-00d8", ["Xbox One Controller", ""],	; Unknown Controller
    "0fff-02a1", ["Xbox One Controller", ""],	; Unknown Controller
    "045e-0867", ["Xbox One Controller", ""],	; Unknown Controller
    "16d0-0f3f", ["Xbox One Controller", ""],	; Unknown Controller
    "2f24-008f", ["Xbox One Controller", ""],	; Unknown Controller
    "0e6f-f501", ["Xbox One Controller", ""],	; Unknown Controller
    "05ac-0001", ["Apple Controller", ""],	; MFI Extended Gamepad (generic entry for iOS/tvOS)
    "05ac-0002", ["Apple Controller", ""],	; MFI Standard Gamepad (generic entry for iOS/tvOS)
    "057e-2006", ["Switch JoyCon (L)", ""],    ; Nintendo Switch Joy-Con (Left)
    "057e-2007", ["Switch JoyCon (R)", ""],   ; Nintendo Switch Joy-Con (Right)
    "057e-2008", ["Switch JoyCons", ""],    ; Nintendo Switch Joy-Con (Left+Right Combined)
    "057e-2009", ["Switch Pro Controller", ""],        ; Nintendo Switch Pro Controller
    "057e-2017", ["Switch Pro Controller", ""],        ; Nintendo Online SNES Controller
    "057e-2019", ["Switch Pro Controller", ""],        ; Nintendo Online N64 Controller
    "057e-201e", ["Switch Pro Controller", ""],        ; Nintendo Online SEGA Genesis Controller
    "0f0d-00c1", ["Switch Pro Controller", ""],  ; HORIPAD for Nintendo Switch
    "0f0d-0092", ["Switch Pro Controller", ""],  ; HORI Pokken Tournament DX Pro Pad
    "0f0d-00f6", ["Switch Pro Controller", ""],		; HORI Wireless Switch Pad
    "0f0d-00dc", ["Switch Pro Controller (XInput)", ""],	 ; HORIPAD S - Looks like a Switch controller but uses the Xbox 360 controller protocol, there is also a version of this that looks like a GameCube controller
    "0e6f-0180", ["Switch Pro Controller", ""],  ; PDP Faceoff Wired Pro Controller for Nintendo Switch
    "0e6f-0181", ["Switch Pro Controller", ""],  ; PDP Faceoff Deluxe Wired Pro Controller for Nintendo Switch
    "0e6f-0184", ["Switch Pro Controller", ""],  ; PDP Faceoff Wired Deluxe+ Audio Controller
    "0e6f-0185", ["Switch Pro Controller", ""],  ; PDP Wired Fight Pad Pro for Nintendo Switch
    "0e6f-0186", ["Switch Pro Controller", ""],        ; PDP Afterglow Wireless Switch Controller - working gyro. USB is for charging only. Many later "Wireless" line devices w/ gyro also use this vid/pid
    "0e6f-0187", ["Switch Pro Controller", ""],  ; PDP Rockcandy Wired Controller
    "0e6f-0188", ["Switch Pro Controller", ""],  ; PDP Afterglow Wired Deluxe+ Audio Controller
    "0f0d-00aa", ["Switch Pro Controller", ""],  ; HORI Real Arcade Pro V Hayabusa in Switch Mode
    "20d6-a711", ["Switch Pro Controller", ""],  ; PowerA Wired Controller Plus/PowerA Wired Controller Nintendo GameCube Style
    "20d6-a712", ["Switch Pro Controller", ""],  ; PowerA Nintendo Switch Fusion Fight Pad
    "20d6-a713", ["Switch Pro Controller", ""],  ; PowerA Super Mario Controller
    "20d6-a714", ["Switch Pro Controller", ""],  ; PowerA Nintendo Switch Spectra Controller
    "20d6-a715", ["Switch Pro Controller", ""],  ; Power A Fusion Wireless Arcade Stick (USB Mode) Over BT is shows up as 057e 2009
    "20d6-a716", ["Switch Pro Controller", ""],  ; PowerA Nintendo Switch Fusion Pro Controller - USB requires toggling switch on back of device
    "20d6-a718", ["Switch Pro Controller", ""],  ; PowerA Nintendo Switch Nano Wired Controller
    "28de-1101", ["Steam Controller", ""],	; Valve Legacy Steam Controller (CHELL)
    "28de-1102", ["Steam Controller", ""],	; Valve wired Steam Controller (D0G)
    "28de-1105", ["Steam Controller", ""],	; Valve Bluetooth Steam Controller (D0G)
    "28de-1106", ["Steam Controller", ""],	; Valve Bluetooth Steam Controller (D0G)
    "28de-11ff", ["Steam Controller", "Steam Virtual Gamepad"],	; Steam virtual gamepad
    "28de-1142", ["Steam Controller", ""],	; Valve wireless Steam Controller
    "28de-1201", ["Steam Controller", ""],	; Valve wired Steam Controller (HEADCRAB)
    "28de-1202", ["Steam Controller", ""],	; Valve Bluetooth Steam Controller (HEADCRAB)
    "28de-1205", ["Steam Controller", ""],	; Valve Steam Deck Builtin Controller
) 

; gets the specific controller name of the device based on vendorID & productID
;  vendorID - device vendorID
;  productID - device vendorID
;
; returns a string with the controller name, defaulting to the controller type
getInputDeviceName(vendorID, productID) {
    vidHex := Format("{:x}", vendorID) 
    loop Max((4 - StrLen(vidHex)), 0) {
        vidHex := "0" . vidHex
    }

    pidHex := Format("{:x}", productID)
    loop Max((4 - StrLen(pidHex)), 0) {
        pidHex := "0" . pidHex
    }

    deviceKey := vidHex . "-" . pidHex
    if (SDL_DEVICE_NAMES.Has(deviceKey)) {
        if (SDL_DEVICE_NAMES[deviceKey][2] != "") {
            return SDL_DEVICE_NAMES[deviceKey][2]
        }
        else {
            return SDL_DEVICE_NAMES[deviceKey][1]
        }
    }

    return ""
}

; calculates the crc16 key from SDL because it can't use normal device codes
; taken from https://github.com/libsdl-org/SDL/blob/main/src/stdlib/SDL_crc16.c
;  hash - string to calculate the crc from (usually device name)
;
; returns crc16
calculateSDLCRC16(hash) {
    crc := 0
    loop StrLen(hash) {
        hashIndex := A_Index
        r := crc ^ Ord(SubStr(hash, hashIndex, 1))
        
        tempCRC := 0
        loop 8 {
            tempCRC := ((tempCRC ^ r) & 1 ? 0xA001 : 0) ^ tempCRC >> 1
            r >>= 1
        }

        crc := tempCRC ^ crc >> 8
    }

    return crc
}