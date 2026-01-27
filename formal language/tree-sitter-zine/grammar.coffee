import {desugar, unthisify} from './sugar.js'

export default grammar desugar unthisify
	name: 'zine'
	extras: -> []
	word: -> @.identifier
	conflicts: -> [
		[@.interval, @.elements]
	]
	rules:
		text: -> seq @.token, repeat seq ' ', @.token
		punctuation: -> /[.!?:;,]/
		token:
			span: -> seq field('keyword', /[a-z]+\{/), @.text, '}'
			word: -> /[^ \r\n{}]+/
			math:
				display: -> seq '{{', @.expression, '}}'
				inline: -> seq '{', @.expression, '}'

		_expression: -> choice(
			prec.left 1, seq ' ', @._expression
			@.expression
		)
		expression:
			atom:
				identifier: -> /[a-zA-Z]+/
				integer: -> /[0-9]+/
				script:
					superscript: -> prec.right seq choice(@.atom, @.parens), '^', choice @.atom, @.parens
					subscript: -> prec.right seq @.atom, '_', choice @.atom, @.parens
				postfix: -> seq @.atom, field 'operator', /[!#']/
			noncommutative: -> choice(
				prec.left 2, seq @._expression, ' ', @._expression
				prec.left seq @.parens, @.parens
			)
			commutative: -> prec.left 3, seq(
				@.expression
				field 'operator', choice ' + ', ' - '
				choice @.expression, @.ellipsis
			)
			set: -> seq '[', choice(@.elements, seq @.expression, '|', @.expression), ']'
			bra: -> seq '<', @.expression, '|'
			ket: -> seq '|', @.expression, '>'
			projection: -> prec 1, seq '<', @.expression, '|', @.expression, '>'
			interval: -> seq(
				field 'start', choice '(', '['
				@.expression, ',', @.expression
				field 'end', choice ')', ']'
			)
			parens: -> seq '(', @.expression, ')'
		elements: -> seq @.expression, repeat seq ',', @.expression
		ellipsis: -> '...'
