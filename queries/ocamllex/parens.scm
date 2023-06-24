(character_set [
    "[" @left.square (#set! "right" "]")
    "]" @right.square
])
(parenthesized_regexp [
   "(" @left.round (#set! "right" ")")
   ")" @right.round
])
