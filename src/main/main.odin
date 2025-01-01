package main

import "../core/lexer"
import "../core/parser"
import "../core/types"
import "core:fmt"

main :: proc() {
	input := `do function_name () returns NUMBER {
	ensure number x is 10;
	number y is 20;
	number z is x plus y;

	return z;
	};
	`

	// input := `ensure y is 10;
	//

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
		case .NUMBER, .STRING, .BOOLEAN, .FLOAT, .NOTHING:
			fmt.printfln("Token: Literal found, Value: %v", lexer.get_current_token_literal(l))
		case .DO, .ENSURE, .IS, .NOW, .PLUS, .MINUS, .TIMES, .DIVIDE:
			fmt.printfln("Token: Keyword found, Value: %v ", lexer.get_current_token_literal(l))
		case:
			fmt.printfln("Token: Symbol found, Value: %v", lexer.get_current_token_literal(l))
		}
	}
}
