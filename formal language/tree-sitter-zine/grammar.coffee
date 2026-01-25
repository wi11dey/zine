export default grammar
  name: 'zine'
  extras: ($) -> []
  supertypes: ($) -> [$.expression]
  rules:
    full: ($) -> seq $.root, /\s*/
    root: ($) -> choice $._spacer, $.expression
    expression: ($) -> choice(
      $.identifier
      $.multiplication
      $.division
      $.parens
      $.addition
      $.subtraction
      $.negation
      $.integer
      $.postfix
    )
    postfix: ($) -> seq $.root, /['!#]/
    integer: ($) -> /[0-9]+/
    subscript: ($) -> seq $.root, '_', $.root
    superscript: ($) -> seq $.root, '^', $.root
    identifier: ($) -> /[a-zA-Z]+/
    set_builder: ($) -> seq '{', $.root, '|', $.root, '}'
    parens: ($) -> seq '(', $.root, ')'
    bra: ($) -> seq '<', $.root, '|'
    ket: ($) -> seq '|', $.root, '>'
    projection: ($) -> seq '<', $.root, '|', $.root, '>'
    interval: ($) -> seq(
      field('start', choice '(', '[')
      $.root, ',', $.root
      field('end', choice ')', ']')
    )
    multiplication: ($) -> choice(
      prec.left 3, seq $.root, ' ', $.root
      prec.left 1, seq $.root, $.parens
      prec.left 3, seq $.parens, $.parens
    )
    _spacer: ($) -> prec.left 2, seq ' ', $.root
    division: ($) -> prec.left seq $.root, '/', $.root
    addition: ($) -> prec.left seq $.root, '+', $.root
    subtraction: ($) -> prec.left seq $.root, '-', $.root
    negation: ($) -> prec.left 4, seq '-', $.root
