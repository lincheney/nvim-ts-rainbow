; inherits _curly,_square,_comma

(block_scalar) @scope.scalar

(block_mapping) @scope.mapping
(block_mapping_pair . key: _ @middle.mapping (#set! jump true) (#set! indent_next 1) (#set! align_with mapping) (#set! align_start true) )
; do not indent next line if inline value
(block_mapping_pair value: (flow_node) @middle._value (#set! indent_next 0) (#set! no_highlight true))

(block_sequence) @scope.sequence
(block_sequence_item . "-" @middle.sequence (#set! jump true) (#set! indent_next 1))
; do not indent next line if inline value
(block_sequence_item (flow_node) @middle._value . (#set! indent_next 0) (#set! no_highlight true) (#set! align_with sequence) )
