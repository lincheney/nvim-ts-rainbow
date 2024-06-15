; inherits: _square,_round,_curly,_comma
("function" @left.block (#set! "right" "\nend"))
(function_declaration "end" @right.block)
(function_definition "end" @right.block)

(do_statement "do" @left.block (#set! "right" "\nend"))
(ERROR ("do" @left.block (#set! "right" "\nend")))
(do_statement "end" @right.block)

("while" @left.block (#set! "right" " do"))
("while" @left.block (#set! "right" "\nend") "do" @middle.block (#eq? @middle.block "do"))
(ERROR ("while" @left.block (#set! "right" "\nend")) ("do" @middle.block (#eq? @middle.block "do") ))
(while_statement "do" @middle.block)
(while_statement "end" @right.block)

("for" @left.block (#set! "right" " do"))
("for" @left.block (#set! "right" "\nend") "do" @middle.block (#eq? @middle.block "do"))
(ERROR ("for" @left.block (#set! "right" "\nend")) ("do" @middle.block (#eq? @middle.block "do") ))
(for_statement "do" @middle.block)
(for_statement "end" @right.block)

("if" @left.if (#set! "right" " then\n"))
("if" @left.if (#set! "right" "\nend") "then" @middle.if (#eq? @middle.if "then"))
(ERROR ("if" @left.if (#set! "right" "\nend")) ("then" @middle.if (#eq? @middle.if "then") ))
("elseif" "then" @middle.if)
("elseif" @middle.if (#set! @middle.if "jump" "true") (#set! align_with if) "then" @_then (#eq? @_then "then") )
("elseif" @left.wrong (#set! align_with if) (#set! "right" " then\n"))
("else" @middle.if (#set! "jump" "true") (#set! align_with if))
("then" @middle.if (#set! align_with if))
(if_statement "end" @right.if)

("repeat" @left.repeat-until (#set! "right" "\nuntil "))
"until" @right.repeat-until

; then anywhere else is wrong
"then" @left.wrong
"end" @left.wrong
