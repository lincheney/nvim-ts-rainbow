; inherits: _square,_round,_curly,_comma
"function" @left.block
"while" @left.block
"for" @left.block
(do_statement "do" @left.block)
"do" @middle.block
"if" @left.block
"then" @middle.block
"elseif" @middle.block
"else" @middle.block
"end" @right.block
"repeat" @left.repeat-until
"until" @right.repeat-until
