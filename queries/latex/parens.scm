; inherits: _square,_round,_curly
("\\[" @left.square.escaped (#set! "right" "\\]"))
"\\]" @right.square.escaped
("\\(" @left.round.escaped (#set! "right" "\\("))
"\\)" @right.round.escaped
