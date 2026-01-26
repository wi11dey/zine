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
			$.number
			$.multiplication
			$.set
			$.bra
			$.ket
			$.interval
		)
		identifier: ($) -> /[a-zA-Z]+/
		number: ($) -> /[0-9]+/
		multiplication: ($) -> prec.left 3, seq $._expression, ' ', $._expression
		set: ($) -> seq '{', $._unspaced, '|', $._unspaced, '}'
		bra: ($) -> seq '<', $._unspaced, '|'
		ket: ($) -> seq '|', $._unspaced, '>'
		interval: ($) -> seq(
			field 'start', choice '(', '['
			$._unspaced, ',', $._unspaced
			field 'end', choice ')', ']'
		)
		# binary: ($) -> prec.left seq $._unspaced, $.binop, choice $._unspaced, '...'
		# binop: ($) -> choice(
		# 	' + '
		# 	'/'
		# )
		# exists: ($) -> seq 'E', $.expression, '. ', $.expression
		# forall: ($) -> seq 'A', $.expression, '. ', $.expression
		# postfix: ($) -> seq $.root, /['!#]/
		# integer: ($) -> /[0-9]+/
		# subscript: ($) -> prec.left 2, seq $.root, '_', $.expression
		# superscript: ($) -> prec.left 2, seq $.root, '^', $.expression
		# parens: ($) -> seq '(', /\s*/, $.root, /\s*/, ')'
		# choice(
		# 	prec.left 3, seq $.expression, ' ', $.expression
		# 	prec.left 1, seq $.root, $.parens
		# 	prec.left 3, seq $.parens, $.parens
		# )
		# division: ($) -> prec.left seq $.root, '/', $.root
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
