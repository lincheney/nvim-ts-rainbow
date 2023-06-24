; inherits: _square,_round,_curly,_comma
(bitstring
  ("<<" @left.angle.double (#set! "right" ">>")
  ">>" @right.angle.double)
(map
  ("{" @left.curly (#set! "right" "}")
  "}" @right.curly)
(interpolation
  ("#{" @left.curly (#set! "right" "}")
  "}" @right.curly)
(sigil
  (sigil_name) @left.sigil
  (sigil_modifiers) @right.sigil)
