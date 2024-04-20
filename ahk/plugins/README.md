# Plugins
Windows Consolizer supports loading plugins that comprise of either config files, AHK library files, or combinations of both. There are 4 main types of plugins.

## AHK
AHK plugins are strictly AHK library files that contain specific supported functions that override default functionality of the Consolizer.

- `customBoot` - user defined function that runs after the threads are initialized, but before any program monitoring begins
- `customLoadScreen` - takes a `Gui` object as its only parameter, then performs modifications to the `Gui`  and returns the modified object.

## Consoles
Console plugins are strictly config files that reference one or more Program plugins that allow different applications to be run with different parameters based on the arguments passed to the Console.

This is most commonly used to set a default emulator when a rom file is launched with a console. Each different rom can have its own default config, automatically choosing the emulator and settings based on the config in the Console.

## Controllers
Controller plugins are combination configs and AHK libraries that allow the Consolizer to read controllers. The libraries contain the actual code to allow the controller state to be read by the Consolizer, with the config files describing different aspects on how those libraries are loaded.

A separate controller thread is loaded for each controller plugin loaded.

## Programs
Program plugins are combination configs and AHK libraries that control how the Consolizer interfaces with different running programs. 

TODO - details
