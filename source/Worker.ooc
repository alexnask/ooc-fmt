use rock
import rock/frontend/[BuildParams, AstBuilder, Token]
import rock/middle/Module
import io/Writer
import OocGen

Worker: class {
    init: func(=input, =writer)

    run: func {
        params := BuildParams new("./")
        // GOGOGO
        module := Module new(input[0..-5], "", params, nullToken)
        module token = Token new(0, 0, module)
        module main = true

        AstBuilder new(input, module, params)

        // Essentially launches our ooc -> formated ooc "backend"
        OocGen new(module, writer) startVisit()
    }

    input: String
    writer: Writer
}
