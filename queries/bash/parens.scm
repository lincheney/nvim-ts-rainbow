; inherits: _curly,_square

("[[" @left.square.double (#set! "right" "]]"))
; "&&" @middle.square.double
; "||" @middle.square.double
"]]" @right.square.double

("((" @left.round.double (#set! "right" "))"))
("$((" @left.round.double (#set! "right" "))"))
"))" @right.round.double

("$(" @left.round (#set! "right" ")"))
("<(" @left.round (#set! "right" ")"))
(">(" @left.round (#set! "right" ")"))
("${" @left.curly (#set! "right" "}"))

("if" @left.if (#set! "right" "\nfi") "then")
(ERROR ("if" @left.if (#set! "right" " then")) ([";" ";;" "&"] @term (#lua-match? @term ".")) . )
("if" @left.if (#set! "right" ";"))
(if_statement "then" @middle.if)
("elif" @middle.if (#set! "jump" "true"))
(elif_clause "then" @middle.if)
("else" @middle.if (#set! "jump" "true"))
"fi" @right.if

("if" @left.if (#set! "right" "\nfi") "then")
("if" @left.if (#set! "right" " then"))

(["while" "until" "for"] @left.block (#set! "right" "\ndone") (do_group "do"))
(ERROR (["while" "until" "for"] @left.block (#set! "right" " do")) ([";" ";;" "&"] @term (#lua-match? @term ".")) . )
(["while" "until" "for"] @left.block (#set! "right" ";"))
(for_statement "in" @middle.block)
(do_group "do" @middle.block)
"done" @right.block

(ERROR ("case" @left.case (#set! "right" "\nesac")) ("in" @in (#eq? @in "in") ))
("case" @left.case (#set! "right" " in"))
(case_statement "in" @middle.case)
(case_item ")" @middle.case (#set! "jump" "true"))
(case_item [";;" ";&" ";;&"] @middle.case)
"esac" @right.case

; do it after the case
("(" @left.round (#set! "right" ")"))
")" @right.round
