; inherits: _square,_round,_curly,_comma

(template_substitution
  "${" @left.curly (#set! "right" "}")
  "}" @right.curly)
