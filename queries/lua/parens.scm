; inherits: square,round,curly,comma
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
(string start: _ @left.square.double.string (#match? @left.square.double.string "\\[[=]*\\[") )
(string end: _ @right.square.double.string (#match? @right.square.double.string "\\][=]*\\]") )
