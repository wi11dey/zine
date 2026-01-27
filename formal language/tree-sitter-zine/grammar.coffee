import {desugar, unthisify} from './sugar.js'

# TODO double-check precedence

export default grammar desugar unthisify
	name: 'zine'
	extras: -> [] # Whitespace-sensitive language
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
			prec.left 2, seq ' ', @._expression
			@.expression
		)
		expression:
			atom:
				identifier: -> /[a-zA-Z]+/
				integer: -> /[0-9]+/
				script:
					superscript: -> prec.right seq(
						choice @.atom, @.parens, @.norm
						'^'
						choice @.atom, @.parens, @.negation
					)
					subscript: -> prec.right seq(
						choice @.atom, @.norm
						'_'
						choice @.atom, @.parens, @.negation
					)
				postfix: -> seq @.atom, field 'operator', /[!#']/
			negation: -> prec 2, seq '-', choice @.atom, @.parens
			noncommutative: -> choice(
				prec.left 3, seq @._expression, ' ', @._expression
				prec.left seq @.parens, @.parens
			)
			commutative: -> prec.left 1, seq(
				@._expression
				field 'operator', choice ' + ', ' - '
				choice @._expression, @.ellipsis
			)
			norm: -> seq '|', @.expression, '|'
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
		elements: -> seq(
			@.expression, ',', @.expression
			repeat seq ',', @.expression
			optional seq ',', @.ellipsis, optional seq ',', @.expression, repeat seq ',', @.expression
		)
		ellipsis: -> '...'
