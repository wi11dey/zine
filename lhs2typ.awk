#!/usr/bin/awk -f

/^>/ {
    if (!code) {
        print "```haskell"
        code = 1
    }
    print substr($0, 2)
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
    }
}
