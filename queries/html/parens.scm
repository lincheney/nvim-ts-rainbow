(element
    . (start_tag
        "<" @middle.element
        (tag_name) @middle.element
        (attribute (attribute_name) @middle.element)*
        ">" @middle.element
    ) @skip.start_tag

    (end_tag
        "</" @middle.element
        (tag_name) @middle.element
        ">" @middle.element
    ) .
) @scope.element

(self_closing_tag
    "<" @middle.element
    (tag_name) @middle.element
    (attribute (attribute_name) @middle.element)*
    "/>" @middle.element
)

(element . (start_tag) @left.erroneous_start_tag )
(erroneous_end_tag) @right.erroneous_end_tag
