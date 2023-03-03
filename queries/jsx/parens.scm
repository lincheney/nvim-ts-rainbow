(
   jsx_opening_element
   "<" @left.jsx_element
   name: _ @middle.jsx_element
   ">" @middle.jsx_element
)

(
   jsx_closing_element
   "<" @middle.jsx_element
   "/" @middle.jsx_element
   name: _ @middle.jsx_element
   ">" @right.jsx_element
)

(
   jsx_self_closing_element
   "<" @left.jsx_element.self
   name: _ @middle.jsx_element.self
   "/" @middle.jsx_element.self
   ">" @right.jsx_element.self
)
