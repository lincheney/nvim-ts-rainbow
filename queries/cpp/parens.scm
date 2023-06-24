; inherits: _curly,_round,_square,_comma

(template_argument_list
  "<" @left.angle  (#set! "right" ">")
  ">" @right.angle)

(template_parameter_list
  "<" @left.angle (#set! "right" ">")
  ">" @right.angle)
