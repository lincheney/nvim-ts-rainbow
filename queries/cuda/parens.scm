; inherits: cpp

(kernel_call_syntax
  "<<<" @left.angle.triple (#set! "right" ">>>")
  ">>>" @right.angle.triple)
