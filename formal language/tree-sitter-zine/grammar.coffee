export default grammar
	name: 'zine'
	extras: ($) -> []
	# supertypes: ($) -> [$.expression]
	word: ($) -> $.identifier
	rules:
		source: ($) -> $._expression
		# root: ($) -> choice $._spacer, $.expression
		_expression: ($) -> choice(
			$._spacer
			$.identifier
			$.multiplication
			# $.parens
			# $.binary
			# $.negation
			# $.integer
			# $.postfix
			# $.subscript
			# $.superscript
			# $.bra
			# $.ket
			# $.set
		)
		# exists: ($) -> seq 'E', $.expression, '. ', $.expression
		# forall: ($) -> seq 'A', $.expression, '. ', $.expression
		# postfix: ($) -> seq $.root, /['!#]/
		# integer: ($) -> /[0-9]+/
		# subscript: ($) -> prec.left 2, seq $.root, '_', $.expression
		# superscript: ($) -> prec.left 2, seq $.root, '^', $.expression
		identifier: ($) -> /[a-zA-Z]+/
		# set: ($) -> seq '{', $.expression, '|', $.expression, '}'
		# parens: ($) -> seq '(', /\s*/, $.root, /\s*/, ')'
		# bra: ($) -> seq '<', $.expression, '|'
		# ket: ($) -> seq '|', $.expression, '>'
		# projection: ($) -> seq '<', $.root, '|', $.root, '>'
		# interval: ($) -> seq(
			# field('start', choice '(', '[')
			# $.root, ',', $.root
			# field('end', choice ')', ']')
		# )
		multiplication: ($) -> prec.left 3, seq $._expression, ' ', $._expression
		# choice(
		# 	prec.left 3, seq $.expression, ' ', $.expression
		# 	prec.left 1, seq $.root, $.parens
		# 	prec.left 3, seq $.parens, $.parens
		# )
		_spacer: ($) -> prec.left 2, seq ' ', $._expression
		# division: ($) -> prec.left seq $.root, '/', $.root
		# binary: ($) -> prec.left seq $.root, /\s*/, $.binop, /\s*/, choice $.root, '...'
		# binop: -> choice(
			# '+'
			# '-'
			# '/'
			# '='
			# '*'
			# '<'
			# '>'
			# '==>'
			# '<=='
			# '<=>'
			# '<='
			# '>='
			# ':='
			# 'and'
			# 'or'
			# 'in'
			# 'contains'
		# )
		# negation: ($) -> prec.left 4, seq '-', $.root
		# not: ($) -> prec.left 4, seq 'not', '\s+', $.root
