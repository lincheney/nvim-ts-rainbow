; inherits: ecma
(type_arguments
  "<" @left.angle (#set! "right" ">")
  ">" @right.angle)
(type_parameters
  "<" @left.angle (#set! "right" ">")
  ">" @right.angle)
(template_type
  "${" @left.curly (#set! "right" "}")
  "}" @right.curly)
