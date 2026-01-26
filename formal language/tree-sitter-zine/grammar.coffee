export default grammar
	name: 'zine'
	supertypes: ($) -> [$.math]
	extras: ($) -> []
	word: ($) -> $.identifier
	rules:
		math: ($) -> choice $.display, $.inline
		display: ($) -> seq '$$', $._expression, '$'
		inline: ($) -> seq '$', $._expression, '$'
		_expression: ($) -> choice(
			$._spacer
			$._unspaced
		)
		_unspaced: ($) -> choice(
			$.identifier
			$.integer
			$.noncommutative
			$.commutative
			$.set
			$.bra
			$.ket
			$.projection
			$.interval
			$.parens
		)
		ellipsis: ($) -> '...'
		identifier: ($) -> /[a-zA-Z]+/
		integer: ($) -> /[0-9]+/
		_spacer: ($) -> prec.left 1, seq ' ', $._expression
		noncommutative: ($) -> choice(
			prec.left 2, seq $._expression, ' ', $._expression
			prec.left seq $.parens, $.parens
		)
		commutative: ($) -> prec.left 3, seq(
			$._unspaced
			field 'operator', choice ' + ', ' - '
			choice $._unspaced, $.ellipsis
		)
		set: ($) -> seq '{', $._unspaced, '|', $._unspaced, '}'
		bra: ($) -> seq '<', $._unspaced, '|'
		ket: ($) -> seq '|', $._unspaced, '>'
		projection: ($) -> prec 1, seq '<', $._unspaced, '|', $._unspaced, '>'
		interval: ($) -> seq(
			field 'start', choice '(', '['
			$._unspaced, ',', $._unspaced
			field 'end', choice ')', ']'
		)
		parens: ($) -> seq '(', $._unspaced, ')'
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
