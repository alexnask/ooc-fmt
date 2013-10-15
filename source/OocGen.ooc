use rock
import structs/[ArrayList, List]
import io/Writer
import rock/middle/[Module, FunctionDecl, FunctionCall, Expression, Type,
    BinaryOp, IntLiteral, FloatLiteral, CharLiteral, StringLiteral,
    RangeLiteral, NullLiteral, VariableDecl, If, Else, While, Foreach,
    Conditional, ControlStatement, VariableAccess, Include, Import,
    Use, TypeDecl, ClassDecl, CoverDecl, Node, Parenthesis, Return,
    Cast, Comparison, Ternary, BoolLiteral, Argument, Statement,
    AddressOf, Dereference, CommaSequence, UnaryOp, ArrayAccess, Match,
    FlowControl, InterfaceDecl, Version, Block, EnumDecl, ArrayLiteral,
    ArrayCreation, StructLiteral, FuncType, NamespaceDecl, Visitor]


// Group multiple imports and return their common path and a list of their names
groupImportPaths: func(importsAtI: ArrayList<String>) -> (String, ArrayList<String>) {
    getPath := func(str: String) -> String {
        str substring(0, str findAll("/") last())
    }
    getName := func(str: String) -> String {
        str substring(str findAll("/") last() + 1)
    }

    group := ArrayList<String> new(importsAtI getSize())
    name := getName(importsAtI[0])
    firstPath := getPath(importsAtI removeAt(0))
    group add(name)

    j := 0
    while(j < importsAtI getSize()) {
        thisPath := getPath(importsAtI[j])
        if(firstPath == thisPath) {
            group add(getName(importsAtI removeAt(j)))
            j -= 1
        }
        j += 1
    }
    (firstPath, group)
}

// Merge many imports together (e.g. a/b/c, a/b/d, a/t, b/c/d/e => "a/b/[c,d]" , "a/t", "b/c/d/e")
importStrings: func(imports: List<Import>) -> ArrayList<String> {
    result := ArrayList<String> new(imports getSize())
    max := 0
    // We must group together as far up as possible
    partLengths := ArrayList<Int> new(imports getSize())
    imports each(|imp|
        len := imp path findAll("/") getSize()
        if(max < len) max = len
        partLengths add(len)
    )

    i := max
    while(i > 0) {
        importsAtI := ArrayList<String> new()
        partLengths each(|len, idx|
            if(len == i) importsAtI add(imports[idx] path)
        )

        if(i > 1) {

            // We make all groups possible for that length of parts and generate the string we need!
            while(importsAtI getSize() > 0) {
                (path, group) := groupImportPaths(importsAtI)
                groupString := path + '/'
                if(group getSize() == 1) {
                    groupString = path + group[0]
                } else {
                    groupString += "[%s]" format(group join(", "))
                }
                result add(groupString)
            }
        } else {
            singleImports := ArrayList<String> new()
            partLengths each(|len, idx|
                if(len == 1) singleImports add(imports[idx] path)
            )

            result add(singleImports join(", "))
        }

        i -= 1
    }
    result
}


OocGen: class extends Visitor {

    init: func(=base, =writer)

    startVisit: func {
        visitModule(base)
    }

    /*
     * Visiting and writing!
     */
    visitModule: func(module: Module) {
        written? := false
        separateSection := func() {
            if(written?) {
                outln("")
                written? = false
            }
        }


        // First, write uses
        module getUses() each(|uze|
            outln("use %s" format(uze identifier))
            if(!written?) written? = true
        )

        separateSection()

        // Now write includes
        module includes each(|inc|
            out("include %s" format(inc path))
            if(inc defines && !inc defines empty?()) {
                first? := true
                out(" | (", false)
                inc defines each(|def|
                    if(first?) {
                        first? = false
                    } else out(", ", false)

                    out("%s = %s" format(def name, def value), false)
                )
                out(")", false)
            }
            outln("", false)
            if(!written?) written? = true
        )

        separateSection()

        // And then imports! First namespaces, then global imports!
        module namespaces each(|ns|
            impString := importStrings(ns getImports()) join(", ")
            outln("import %s into %s" format(impString, ns name))
            if(!written?) written? = true
        )

        imports := importStrings(module imports)
        imports each(|imp|
            outln("import %s" format(imp))
            if(!written?) written? = true
        )

        separateSection()
    }


    /*
     * Writing stuff
     */

    indent: func {
        indentLevel += 1
    }

    outdent: func {
        if(indentLevel > 0) indentLevel -= 1
    }

    out: func(str: String, indent?: Bool = true) {
        if(indent?) writer write(" " times(4 * indentLevel))
        writer write(str)
    }

    outln: func(str: String, indent?: Bool = true) {
        out(str, indent?); out("\n", false)
    }

    indentLevel := 0
    writer: Writer
    base: Module
}
