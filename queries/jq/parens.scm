; inherits: _square,_round,_curly,_comma

("\\(" @left.round (#set! "right" ")"))

("if" @left.if (#set! "right" " then\n"))
("if" @left.if (#set! "right" "\nend") "then" @middle.if (#eq? @middle.if "then"))
(ERROR ("if" @left.if (#set! "right" "\nend")) ("then" @middle.if (#eq? @middle.if "then") ))
("elif" "then" @middle.if)
("elif" @middle.if (#set! @middle.if "jump" "true") (#set! align_with if) "then" @_then (#eq? @_then "then") )
("elif" @left.wrong (#set! align_with if) (#set! "right" " then\n"))
("else" @middle.if (#set! "jump" "true") (#set! align_with if))
("then" @middle.if (#set! align_with if))
("if" "end" @right.if)
