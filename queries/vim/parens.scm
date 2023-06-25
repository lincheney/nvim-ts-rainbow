; inherits: _square,_round,_curly,_comma

("if" @left.if (#set! "right" "\nendif"))
("elseif" @middle.if (#set! "jump" "true"))
("else" @middle.if (#set! "jump" "true"))
"endif" @right.if

("function" @left.function (#set! "right" "\nendfunction"))
"endfunction" @right.function

("while" @left.while (#set! "right" "\nendwhile"))
"endwhile" @right.while

("for" @left.for (#set! "right" "\nendfor"))
"endfor" @right.for

("try" @left.try (#set! "right" "\nendtry"))
("catch" @middle.try (#set! "jump" "true"))
("finally" @middle.try (#set! "jump" "true"))
"endtry" @right.try

(pattern _ @left.round.pattern (#any-of? @left.round.pattern "\\(" "\\%(") (#set! "right" "\\)"))
(pattern _ @right.round.pattern (#eq? @right.round.pattern "\\)"))
