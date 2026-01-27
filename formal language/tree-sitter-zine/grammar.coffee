import * as sugar from './sugar.js'

export default grammar sugar.desugar sugar.unthisify
	name: 'zine'
	extras: -> []
	word: -> @.identifier
	rules:
		text: -> repeat1 @.token

		token:
			span: -> seq(
				token seq field('keyword', /[a-z]+/), '{'
				@.text
				'}'
			)
			word: -> /[^ \r\n{}]+/
			math:
				display: -> seq '{{', @.expression, '}}'
				inline: -> seq '{', @.expression, '}'

		_expression: -> choice(
			prec.left 1, seq ' ', @._expression
			@.expression
		)
		expression:
			identifier: -> /[a-zA-Z]+/
			integer: -> /[0-9]+/
			noncommutative: -> choice(
				prec.left 2, seq @._expression, ' ', @._expression
				prec.left seq @.parens, @.parens
			)
			commutative: -> prec.left 3, seq(
				@.expression
				field 'operator', choice ' + ', ' - '
				choice @.expression, @.ellipsis
			)
			set: -> seq '[', @.expression, '|', @.expression, ']'
			bra: -> seq '<', @.expression, '|'
			ket: -> seq '|', @.expression, '>'
			projection: -> prec 1, seq '<', @.expression, '|', @.expression, '>'
			interval: -> seq(
				field 'start', choice '(', '['
				@.expression, ',', @.expression
				field 'end', choice ')', ']'
			)
			parens: -> seq '(', @.expression, ')'

		ellipsis: -> '...'
		# binary: -> prec.left seq @.expression, @.binop, choice @.expression, '...'
		# binop: -> choice(
		# 	' + '
		# 	'/'
		# )
		# exists: -> seq 'E', @.expression, '. ', @.expression
		# forall: -> seq 'A', @.expression, '. ', @.expression
		# postfix: -> seq @.root, /['!#]/
		# integer: -> /[0-9]+/
		# subscript: -> prec.left 2, seq @.root, '_', @.expression
		# superscript: -> prec.left 2, seq @.root, '^', @.expression
		# choice(
		# 	prec.left 3, seq @.expression, ' ', @.expression
		# 	prec.left 1, seq @.root, @.parens
		# 	prec.left 3, seq @.parens, @.parens
		# )
		# division: -> prec.left seq @.root, '/', @.root
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
		# negation: -> prec.left 4, seq '-', @.root
		# not: -> prec.left 4, seq 'not', '\s+', @.root
