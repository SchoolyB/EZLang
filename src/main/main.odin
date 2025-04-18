package main

import "../core/lexer"
import "../core/parser"
import "../core/types"
import "core:fmt"

main :: proc() {
	input := `do main () >>> Number {

	Number x = 1;

	}

	`


	l := lexer.new_lexer(input)
	p := parser.new_parser(l)
	program := parser.parse_program(p)

	if program != nil {
		fmt.println("Parsing successful!")
	} else {
		fmt.println("Parsing failed!")
	}

	// Print all tokens for debugging
	l = lexer.new_lexer(input)
	for token := lexer.next_token(l); token != .EOF; token = lexer.next_token(l) {
		#partial switch token {
		case .IDENTIFIER:
			fmt.printfln("Token: Identifier found, Value: %v", lexer.get_identifier_name(l))
		case .NUMBER, .STRING, .BOOLEAN, .FLOAT, .NULL:
			fmt.printfln("Token: Literal found, Value: %v", lexer.get_current_token_literal(l))
		case .DO, .CONST, .NOW, .EQUALS, .OTHERWISE, .CHECK, .EVENT, .WHILE, .UNTIL, .STOP, .GO_ON :
			fmt.printfln("Token: Keyword found, Value: %v ", lexer.get_current_token_literal(l))
		case :
			fmt.printfln("Token: Symbol found, Value: %v", lexer.get_current_token_literal(l))
		}
	}
}
