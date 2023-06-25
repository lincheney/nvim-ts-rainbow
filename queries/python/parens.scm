; inherits: _square,_round,_curly,_comma

(for_statement "for" @middle.for "in" @middle.for ":" @middle.for
    (else_clause "else" @middle.for ":" @middle.for (#set! "jump" "true"))?
) @scope.for

(while_statement "while" @middle.while ":" @middle.while
    (else_clause "else" @middle.while ":" @middle.while (#set! "jump" "true"))?
) @scope.while

(if_statement "if" @middle.if ":" @middle.if
    (else_clause "else" @middle.if ":" @middle.if (#set! "jump" "true"))?
) @scope.if
(elif_clause "elif" @middle.if ":" @middle.if (#set! "jump" "true"))

(with_statement "with" @middle.with ":" @middle.with) @scope.with

(function_definition "def" @middle.def ":" @middle.def) @scope.def

(class_definition "class" @middle.class ":" @middle.class) @scope.class

(try_statement "try" @middle.try ":" @middle.try
    (except_clause "except" @middle.try ":" @middle.try (#set! "jump" "true"))?
    ; (except_group_clause "except*" @middle.try ":" @middle.try)?
    (else_clause "else" @middle.try ":" @middle.try (#set! "jump" "true"))?
    (finally_clause "finally" @middle.try ":" @middle.try (#set! "jump" "true"))?
) @scope.try

(match_statement "match" @middle.match ":" @middle.match
    (case_clause "case" @middle.match ":" @middle.match (#set! "jump" "true"))?
) @scope.match
