; inherits: _curly,_square

("[[" @left.square.double (#set! "right" "]]"))
; "&&" @middle.square.double
; "||" @middle.square.double
"]]" @right.square.double

("((" @left.round.double (#set! "right" "))"))
"))" @right.round.double

("$(" @left.round (#set! "right" ")"))
("<(" @left.round (#set! "right" ")"))
(">(" @left.round (#set! "right" ")"))
("${" @left.curly (#set! "right" "}"))

("if" @left.if (#set! "right" "\nfi"))
(if_statement "then" @middle.if)
("elif" @middle.if (#set! "jump" "true"))
(elif_clause "then" @middle.if)
("else" @middle.if (#set! "jump" "true"))
"fi" @right.if

("while" @left.block (#set! "right" "\ndone"))
("until" @left.block (#set! "right" "\ndone"))
("for" @left.block (#set! "right" "\ndone"))
(for_statement "in" @middle.block)
(do_group "do" @middle.block)
"done" @right.block

("case" @left.case (#set! "right" "\nesac"))
(case_statement "in" @middle.case)
(case_item ")" @middle.case (#set! "jump" "true"))
"esac" @right.case

; do it after the case
("(" @left.round (#set! "right" ")"))
")" @right.round
