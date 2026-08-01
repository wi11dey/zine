#!/usr/bin/awk -f

/^>/ {
    if (!code) {
        print "```haskell"
        code = 1
    }
    print substr($0, 2)
    next
}
# TODO: merge this into the above
/^\|/ {
    if (code) {
        print "```"
        code = 0
    }
    expr = substr($0, 2)
    print "```haskell"
    print expr
    print "```"

    gsub(/\\/, "\\\\", expr)
    gsub(/"/, "\\\"", expr)
    ghci_options = "-v0 -e \"" expr "\""
    gsub(/'/, "'\\''", ghci_options)
    ghci = "stack ghci zine:exe:zine --ghci-options='" ghci_options "'"
    ghci | getline result
    close(ghci)
    print result
    next
}
{
    if (code) {
        print "```"
        code = 0
    }
    print
}
END {
    if (code) {
        print "```"
        code = 0
    }
}
