/^>/ {
    if (!code) {
	print "```haskell"
	code = 1
    }
    sub(/^> ?/, "")
    print
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
