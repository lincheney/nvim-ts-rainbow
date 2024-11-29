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

(ERROR ("if" @left.if (#set! "right" "; ")) )
(ERROR ("if" @left.if (#set! "right" " then\n")) ([";" ";;" "&"] @term (#lua-match? @term ".")) )
("if" @left.if (#set! "right" "\nfi") "then" @middle.if)
(ERROR ("elif" @left.if (#set! "right" "; ")) )
(ERROR ("elif" @left.if (#set! "right" " then\n")) ([";" ";;" "&"] @term (#lua-match? @term ".")) )
("elif" @middle.if (#set! "jump" "true") "then" @middle.if)
("else" @middle.if (#set! "jump" "true"))
"fi" @right.if

(["while" "until" "for"] @left.block (#set! "right" "; "))
(ERROR (["while" "until" "for"] @left.block (#set! "right" " do")) ([";" ";;" "&"] @term (#lua-match? @term ".")) )
(["while" "until" "for"] @left.block (#set! "right" "\ndone") (do_group "do"))
(for_statement "in" @middle.block)
(do_group "do" @middle.block)
"done" @right.block

("case" @left.case (#set! "right" " in\n"))
(ERROR ("case" @left.case (#set! "right" "\nesac")) ("in" @in (#eq? @in "in") ))
(case_statement "in" @middle.case)
(case_item ["(" ")"] @middle.case (#set! "jump" "true"))
(case_item [";;" ";&" ";;&"] @middle.case)
"esac" @right.case

(heredoc_start) @left.heredoc
(heredoc_end) @right.heredoc

; do it after the case
("(" @left.round (#set! "right" ")"))
")" @right.round
