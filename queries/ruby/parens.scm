; inherits: _square,_round,_curly,_comma

("%w(" @left.round (#set! "right" ")"))
("%i(" @left.round (#set! "right" ")"))
("#{" @left.curly (#set! "right" "}"))
