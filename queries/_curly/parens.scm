(ERROR "}" @right.wrong_curly)
("{" @left.curly (#set! "right" "}"))
"}" @right.curly
