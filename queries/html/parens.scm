(element
    . (start_tag "<" @middle.angle ">" @middle.angle) @skip.start_tag
    (end_tag "</" @middle.angle ">" @middle.angle) .
) @scope.element

(self_closing_tag "<" @middle.angle "/>" @middle.angle) @scope.self_closing_tag

(_
    . (start_tag)
    (_ . (start_tag "<" @middle.angle ">" @middle.angle) @scope.self_closing_tag)
    (end_tag) .
)

(attribute (attribute_name) @middle.attr)*
(_ (tag_name) @middle.tag_name (#set! "jump" "true"))
(erroneous_end_tag) @right.erroneous_end_tag
