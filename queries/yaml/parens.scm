; inherits _curly,_square,_comma

(block_mapping) @scope.mapping
(block_mapping_pair . key: _ @middle.mapping (#set! "jump" "true"))

(block_sequence) @scope.sequence
(block_sequence_item . "-" @middle.sequence)
