class ShenmueProgram extends SteamGameProgram {
    _launch(URI, args*) {
        version := Integer(args.RemoveAt(1))
        if (version = 1) {
            this.launcher["mouseClick"] := [0.250, 0.500]
        }
        else if (version = 2) {
            this.launcher["mouseClick"] := [0.750, 0.500]
        }

        super._launch(URI, args*)
    }
}