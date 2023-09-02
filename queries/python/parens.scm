; inherits: _square,_round,_curly,_comma

(interpolation) @scope.interpolation

(for_statement) @scope.for
(for_statement "for" @middle.for (#set! "jump" "true") "in" @middle.for ":" @middle.for)
(for_statement (else_clause "else" @middle.for (#set! "jump" "true") ":" @middle.for))

(while_statement) @scope.while
(while_statement "while" @middle.while (#set! "jump" "true") ":" @middle.while)
(while_statement (else_clause "else" @middle.while (#set! "jump" "true") ":" @middle.while))

(if_statement) @scope.if
(if_statement "if" @middle.if (#set! "jump" "true") ":" @middle.if)
(if_statement (else_clause "else" @middle.if (#set! "jump" "true") ":" @middle.if))
(elif_clause "elif" @middle.if ":" @middle.if (#set! "jump" "true"))

(with_statement "with" @middle.with ":" @middle.with) @scope.with

(function_definition "def" @middle.def ":" @middle.def) @scope.def

(class_definition "class" @middle.class ":" @middle.class) @scope.class

(try_statement) @scope.try
(try_statement "try" @middle.try (#set! "jump" "true") ":" @middle.try)
(try_statement (except_clause "except" @middle.try (#set! "jump" "true") ":" @middle.try))
; (except_group_clause "except*" @middle.try ":" @middle.try)?
(try_statement (else_clause "else" @middle.try (#set! "jump" "true") ":" @middle.try))
(try_statement (finally_clause "finally" @middle.try (#set! "jump" "true") ":" @middle.try))

(match_statement) @scope.match
(match_statement "match" @middle.match (#set! "jump" "true") ":" @middle.match)
(match_statement (block (case_clause "case" @middle.match (#set! "jump" "true") ":" @middle.match)))
