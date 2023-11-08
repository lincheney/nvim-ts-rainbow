; inherits: _square,_round,_curly,_comma
("function" @left.block (#set! "right" "\nend"))

(do_statement "do" @left.block (#set! "right" "\nend"))
"do" @middle.block
"then" @middle.block

(ERROR ("while" @left.block (#set! "right" "\nend")) ("do" @do (#eq? @do "do") ))
("while" @left.block (#set! "right" " do"))

(ERROR ("for" @left.block (#set! "right" "\nend")) ("do" @do (#eq? @do "do") ))
("for" @left.block (#set! "right" " do"))

(ERROR ("if" @left.block (#set! "right" "\nend")) ("then" @then (#eq? @then "then") ))
("if" @left.block (#set! "right" " then"))

("elseif" @middle.block (#set! "jump" "true"))
("else" @middle.block (#set! "jump" "true"))
"end" @right.block

("repeat" @left.repeat-until (#set! "right" "\nuntil"))
"until" @right.repeat-until
