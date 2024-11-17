(
   (jsx_opening_element name: (identifier) @left.erroneous_start_tag)
   (jsx_closing_element name: (identifier) @right.erroneous_end_tag)
   (#not-eq? @left.erroneous_start_tag @right.erroneous_end_tag)
)

(_
  . (jsx_opening_element
    "<" @middle.angle
    name: (identifier) @middle.tag_name
    ">" @middle.angle
  ) @left.tag (#set! @left.tag "no_highlight" "true")
  (jsx_closing_element name: (identifier) @skip.close_tag) @right.tag
  (#eq? @skip.close_tag @middle.tag_name)
)

(ERROR
  . (jsx_opening_element
    name: (identifier) @skip.tag_name
) @left.erroneous_start_tag )

(jsx_self_closing_element
  "<" @middle.angle
  name: (identifier) @middle.tag_name
  "/>" @middle.angle
) @scope.self_closing_tag

(jsx_attribute (property_identifier) @middle.attr)*
; (erroneous_end_tag) @right.erroneous_end_tag
