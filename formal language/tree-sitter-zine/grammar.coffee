export default grammar
	name: 'zine'
	extras: ($) -> []
	word: ($) -> $.identifier
	rules:
		source: ($) -> $._expression
		_expression: ($) -> choice(
			$._spacer
			$._unspaced
			# $.parens
			# $.binary
			# $.negation
			# $.integer
			# $.postfix
			# $.subscript
			# $.superscript
			# $.bra
			# $.ket
		)
		_spacer: ($) -> prec.left 2, seq ' ', $._expression
		_unspaced: ($) -> choice(
			$.identifier
			$.multiplication
			$.set
		)
		identifier: ($) -> /[a-zA-Z]+/
		multiplication: ($) -> prec.left 3, seq $._expression, ' ', $._expression
		set: ($) -> seq '{', $._unspaced, '|', $._unspaced, '}'
		# exists: ($) -> seq 'E', $.expression, '. ', $.expression
		# forall: ($) -> seq 'A', $.expression, '. ', $.expression
		# postfix: ($) -> seq $.root, /['!#]/
		# integer: ($) -> /[0-9]+/
		# subscript: ($) -> prec.left 2, seq $.root, '_', $.expression
		# superscript: ($) -> prec.left 2, seq $.root, '^', $.expression
		# parens: ($) -> seq '(', /\s*/, $.root, /\s*/, ')'
		# bra: ($) -> seq '<', $.expression, '|'
		# ket: ($) -> seq '|', $.expression, '>'
		# projection: ($) -> seq '<', $.root, '|', $.root, '>'
		# interval: ($) -> seq(
			# field('start', choice '(', '[')
			# $.root, ',', $.root
			# field('end', choice ')', ']')
		# )
		# choice(
		# 	prec.left 3, seq $.expression, ' ', $.expression
		# 	prec.left 1, seq $.root, $.parens
		# 	prec.left 3, seq $.parens, $.parens
		# )
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
