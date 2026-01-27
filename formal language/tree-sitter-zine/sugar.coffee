export desugar = ({ rules: sugared, rest... }) -> {
	rest...
	supertypes: ($) ->
		Array.from do collect = (rules = sugared) ->
			for key, value of rules when typeof value is 'object'
				yield from collect value
				yield $[key]
	rules: Object.assign(
		Object.fromEntries do flatten = (rules = sugared) ->
			for key, value of rules
				if typeof value is 'object'
					yield from flatten value
				else
					yield [key, value]
		Object.fromEntries do choices = (rules = sugared) ->
			for key, value of rules when typeof value is 'object'
				yield from choices value
				yield [
					key
					do (value) -> # Copy value in the returned lambda
						($) -> choice ($[subtype] for subtype in Object.keys value)...
				]
	)
}

export unthisify = (obj) ->
	for key, value of obj
		if typeof value is 'function'
			obj[key] = do (value) -> ($) -> value.bind($)()
		else if typeof value is 'object'
			unthisify value
	obj
