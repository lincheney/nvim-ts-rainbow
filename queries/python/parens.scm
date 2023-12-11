; inherits: _square,_round,_curly,_comma

(interpolation) @scope.interpolation

; do not indent next line if inline block
(_ (block _) @middle._block (#not-lua-match? @middle._block "^%s*$") (#set! indent_next -999) (#set! no_highlight true))
; do not indent in string
(string (#set! indent_next 0)) @scope.string

; indent next line if no block
(for_statement "for" @middle.for "in" @middle.for ":" @middle.for) @scope.for
(for_statement (else_clause "else" @middle.for ":" @middle.for))

(while_statement "while" @middle.while ":" @middle.while) @scope.while
(while_statement (else_clause "else" @middle.while ":" @middle.while))

(if_statement "if" @middle.if ":" @middle.if) @scope.if
(if_statement (_ ["else" "elif"] @middle.if ":" @middle.if))

(with_statement "with" @middle.with ":" @middle.with) @scope.with

(function_definition "def" @middle.def ":" @middle.def) @scope.def

(class_definition "class" @middle.class ":" @middle.class) @scope.class

(try_statement "try" @middle.try ":" @middle.try) @scope.try
(ERROR . "try" @middle.try.text ":" @middle.try (#eq? @middle.try.text "try") (#set! jump true) ) @scope.try
; (except_group_clause "except*" @middle.try ":" @middle.try)?
(try_statement (_  ["except" "else" "finally"]  @middle.try ":" @middle.try))

(match_statement "match" @middle.match ":" @middle.match) @scope.match
(match_statement (block (case_clause "case" @middle.match ":" @middle.match (#set! align_with "^match$") (#set! align_offset 1) )))

(ERROR . (_ "except")  @left._except  (#eq? @left._except  "except")  (#set! align_with "^try$"))
(ERROR . (_ "else")    @left._else    (#eq? @left._else    "else")    (#set! align_with "\\v^(for|while|if|try)$"))
(ERROR . (_ "elif")    @left._elif    (#eq? @left._elif    "elif")    (#set! align_with "^if$"))
(ERROR . (_ "finally") @left._finally (#eq? @left._finally "finally") (#set! align_with "^try$"))
(ERROR . (_ "case")    @left._case    (#eq? @left._case    "case")    (#set! align_with "^match$") (#set! align_offset 1) )

; can jump to the following nodes
(["if" "for" "while" "try" "else" "elif" "except" "finally" "match" "case"] @_nomatch (#set! jump true))
; indent after these nodes
(["else" "elif" "except" "finally" "case"] @_nomatch (#set! indent_next 1))
; dedent after these nodes
(_ ["pass" "raise" "return"] @middle._noindent (#set! no_highlight true) (#set! indent_next -1) )
