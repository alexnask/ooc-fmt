import Worker
import text/Opts
import structs/ArrayList
import io/[File, FileWriter]

main: func(args: ArrayList<String>) -> Int {
    options := Opts new(args)

    /*
     * TODO: add a directory and a recursive option
     */

    if(options set?("V")) {
        "ooc-fmt version 0.1 codename unicorn stool" println()
    } else if(options set?("help") || !options set?("i") || !options set?("o")) {
        "Usage: %s -i=[input] -o=[output]" printfln(options get("self"))
    } else {
        // Let's cut to the chase!
        input := options get("i")
        input = input endsWith?(".ooc") ? input : input + ".ooc"
        output := options get("o")
        output = output endsWith?(".ooc") ? output : output + ".ooc"

        // Check input exists
        if(!File new(input) exists?()) {
            "Input file %s does not exist :(" printfln(input)
            return 1
        }

        // Open up a file writer for the output
        writer := FileWriter new(output)

        // Start our worker!
        Worker new(input, writer) run()
    }

    0
}
