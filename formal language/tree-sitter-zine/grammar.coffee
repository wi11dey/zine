export default grammar
  name: 'zine'
  rules:
    document:    ($) -> repeat $.heading, $.paragraph
    inline:      ($) -> prec.left seq '$', $.expression, '$'
    display:     ($) -> prec.left seq '$$', $.expression, '$$'
    heading:     ($) -> seq field('depth', repeat '#'), $.text, $._newline
    word:        ($) -> /\S+/
    text:        ($) -> repeat choice $.word, $.inline, $.display
    paragraph:   ($) -> seq $.text, $._newline, $._newline
    _newline:    ($) -> choice /\r\n/, /\n/
    _whitespace: ($) -> /[ \t]/