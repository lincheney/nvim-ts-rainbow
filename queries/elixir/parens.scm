; inherits: square,round,curly,comma
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
