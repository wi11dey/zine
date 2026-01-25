export default grammar
  name: 'zine'
  extras: ($) -> []
  supertypes: ($) -> [$.expression]
  word: ($) -> $.identifier
  rules:
    full: ($) -> seq $.root, /\s*/
    root: ($) -> choice $._spacer, $.expression
    expression: ($) -> choice(
      $.identifier
      $.multiplication
      $.parens
      $.binary
      $.negation
      $.integer
      $.postfix
      $.subscript
      $.superscript
      $.bra
      $.ket
      $.set
    )
    exists: ($) -> seq 'E', $.expression, '. ', $.expression
    forall: ($) -> seq 'A', $.expression, '. ', $.expression
    postfix: ($) -> seq $.root, /['!#]/
    integer: ($) -> /[0-9]+/
    subscript: ($) -> prec.left 2, seq $.root, '_', $.expression
    superscript: ($) -> prec.left 2, seq $.root, '^', $.expression
    identifier: ($) -> /[a-zA-Z]+/
    set: ($) -> seq '{', $.expression, '|', $.expression, '}'
    parens: ($) -> seq '(', /\s*/, $.root, /\s*/, ')'
    bra: ($) -> seq '<', $.expression, '|'
    ket: ($) -> seq '|', $.expression, '>'
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
    binary: ($) -> prec.left seq $.root, /\s*/, $.binop, /\s*/, choice $.root, '...'
    binop: -> choice(
      '+'
      '-'
      '/'
      '='
      '*'
      '<'
      '>'
      '==>'
      '<=='
      '<=>'
      '<='
      '>='
      ':='
      'and'
      'or'
      'in'
      'contains'
    )
    negation: ($) -> prec.left 4, seq '-', $.root
    not: ($) -> prec.left 4, seq 'not', '\s+', $.root
