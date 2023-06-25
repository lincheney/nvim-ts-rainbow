; inherits: _square,_round,_curly,_comma
("function" @left.block (#set! "right" "\nend"))
("while" @left.block (#set! "right" "\nend"))
("for" @left.block (#set! "right" "\nend"))
(do_statement "do" @left.block (#set! "right" "\nend"))
"do" @middle.block
("if" @left.block (#set! "right" "\nend"))
"then" @middle.block
("elseif" @middle.block (#set! "jump" "true"))
("else" @middle.block (#set! "jump" "true"))
"end" @right.block
("repeat" @left.repeat-until (#set! "right" "\nuntil"))
"until" @right.repeat-until
