; inherits: round,curly,square
(_
  "[[" @left.square.double
  "]]" @right.square.double)
(command_substitution
  "$(" @left.round
  ")" @right.round)
(expansion
  "${" @left.curly
  "}" @right.curly)
