; inherits: _square,_round,_curly,_comma
("function" @left.block (#set! "right" "\nend"))

(do_statement "do" @left.block (#set! "right" "\nend"))
"do" @middle.block
"then" @middle.block

("while" @left.block (#set! "right" " do"))
("while" @left.block (#set! "right" "\nend") "do" @do (#eq? @do "do"))
(ERROR ("while" @left.block (#set! "right" "\nend")) ("do" @do (#eq? @do "do") ))

("for" @left.block (#set! "right" " do"))
("for" @left.block (#set! "right" "\nend") "do" @do (#eq? @do "do"))
(ERROR ("for" @left.block (#set! "right" "\nend")) ("do" @do (#eq? @do "do") ))

("if" @left.block (#set! "right" " then"))
("if" @left.block (#set! "right" "\nend") "then" @then (#eq? @then "then"))
(ERROR ("if" @left.block (#set! "right" "\nend")) ("then" @then (#eq? @then "then") ))

("elseif" @middle.block (#set! "jump" "true"))
("else" @middle.block (#set! "jump" "true"))
"end" @right.block

("repeat" @left.repeat-until (#set! "right" "\nuntil"))
"until" @right.repeat-until
