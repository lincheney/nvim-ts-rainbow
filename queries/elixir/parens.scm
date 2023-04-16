; inherits: _square,_round,_curly,_comma
(bitstring
  "<<" @left.angle.double
  ">>" @right.angle.double)
(map
  "{" @left.curly
  "}" @right.curly)
(interpolation
  "#{" @left.curly
  "}" @right.curly)
(sigil
  (sigil_name) @left.sigil
  (sigil_modifiers) @right.sigil)
