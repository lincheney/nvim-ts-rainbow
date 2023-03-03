; inherits: square,round,curly
"\\[" @left.square
"\\]" @right.square
"\\(" @left.round
"\\)" @right.round

[
 "\\begin"
 (#latex-extended-rainbow-mode?)] @left.begin_end
[
 "\\end"
 (#latex-extended-rainbow-mode?)] @right.begin_end
