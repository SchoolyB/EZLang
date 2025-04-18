package main

import "../src/core/lexer"
import "../src/core/parser"
import "../src/core/types"
import "core:fmt"
import "core:io"
import "core:os"

main :: proc() {
	mainFile,_:= os.open("./main.ez")
	input,_ := os.read_entire_file(mainFile)

	strInput := string(input)

	l := lexer.new_lexer(strInput)
	p := parser.new_parser(l)
	program := parser.parse_program(p)

	if program != nil {
		fmt.println("Parsing successful!")
	} else {
		fmt.println("Parsing failed!")
	}

	// Print all tokens for debugging
	l = lexer.new_lexer(strInput)
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
