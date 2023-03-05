; inherits: curly,square

"[[" @left.square.double
; "&&" @middle.square.double
; "||" @middle.square.double
"]]" @right.square.double

"$(" @left.round
"<(" @left.round
">(" @left.round
"${" @left.curly

"if" @left.if
(if_statement "then" @middle.if)
"elif" @middle.if
(elif_clause "then" @middle.if)
"else" @middle.if
"fi" @right.if

"while" @left.block
"until" @left.block
"for" @left.block
(for_statement "in" @middle.block)
(do_group "do" @middle.block)
"done" @right.block

"case" @left.case
(case_statement "in" @middle.case)
(case_item ")" @middle.case)
"esac" @right.case

; do it after the case
"(" @left.round
")" @right.round
