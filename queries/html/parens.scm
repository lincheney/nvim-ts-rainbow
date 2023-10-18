(_
  . (start_tag
      "<" @middle.angle
      (tag_name) @middle.tag_name (#set! "jump" "true")
      ">" @middle.angle
  ) @left.tag (#set! "no_highlight" "true")
  (end_tag) @right.tag
)

(_
  . (start_tag
      "<" @middle.angle
        (tag_name) @middle.tag_name (#any-of? @middle.tag_name
            "area"
            "base"
            "br"
            "col"
            "embed"
            "hr"
            "img"
            "input"
            "link"
            "meta"
            "param"
            "source"
            "track"
            "wbr"
        )
      ">" @middle.angle
  ) @scope.void_element
)
(_
  . (start_tag
        (tag_name) @skip.tag_name (#not-any-of? @skip.tag_name
            "area"
            "base"
            "br"
            "col"
            "embed"
            "hr"
            "img"
            "input"
            "link"
            "meta"
            "param"
            "source"
            "track"
            "wbr"
        )
) @left.erroneous_start_tag )

(self_closing_tag
  "<" @middle.angle
  (tag_name) @middle.tag_name
  "/>" @middle.angle
) @scope.self_closing_tag

(attribute (attribute_name) @middle.attr)*
(erroneous_end_tag) @right.erroneous_end_tag
