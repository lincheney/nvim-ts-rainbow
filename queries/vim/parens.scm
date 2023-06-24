; inherits: _square,_round,_curly,_comma

("if" @left.if (#set! "right" "\nendif"))
"elseif" @middle.if
"else" @middle.if
"endif" @right.if

("function" @left.function (#set! "right" "\nendfunction"))
"endfunction" @right.function

("while" @left.while (#set! "right" "\nendwhile"))
"endwhile" @right.while

("for" @left.for (#set! "right" "\nendfor"))
"endfor" @right.for

("try" @left.try (#set! "right" "\nendtry"))
"catch" @middle.try
"finally" @middle.try
"endtry" @right.try

(pattern _ @left.round.pattern (#any-of? @left.round.pattern "\\(" "\\%(") (#set! "right" "\\)"))
(pattern _ @right.round.pattern (#eq? @right.round.pattern "\\)"))
