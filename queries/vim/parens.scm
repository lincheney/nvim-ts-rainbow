; inherits: _square,_round,_curly,_comma

"if" @left.if
"elseif" @middle.if
"else" @middle.if
"endif" @right.if

"function" @left.function
"endfunction" @right.function

"while" @left.while
"endwhile" @right.while

"for" @left.for
"endfor" @right.for

"try" @left.try
"catch" @middle.try
"finally" @middle.try
"endtry" @right.try

(augroup_statement "augroup" @right.augroup . (augroup_name) @name (#eq? @name "END"))
(augroup_statement "augroup" @left.augroup . (augroup_name))

(pattern _ @left.round.pattern (#any-of? @left.round.pattern "\\(" "\\%("))
(pattern _ @right.round.pattern (#eq? @left.round.pattern "\\)"))
