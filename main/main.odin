package main

import "../src/core/lexer"
import "../src/core/parser"
import "../src/core/types"
import "core:fmt"
import "core:io"
import "core:os"
import "../src/utils"

main :: proc() {
	mainFile,_:= os.open("./main.ez")
	input,_ := os.read_entire_file(mainFile)

	strInput := string(input)

	l := lexer.new_lexer(strInput)
	p := parser.new_parser(l)
	program := parser.parse_program(p)

	if program == nil {
		fmt.printfln("%sParsing failed!%s", utils.RED, utils.RESET)
		os.exit(0)
	} else {
		fmt.printfln("%sParsing successful!%s", utils.GREEN,utils.RESET)
		fmt.println("Printing parsed tokens....\n")
	}

	// Print all tokens for debugging
	l = lexer.new_lexer(strInput)
	for token := lexer.next_token(l); token != .EOF; token = lexer.next_token(l) {
		#partial switch token {
		case .IDENTIFIER:
			fmt.printfln("Token: Identifier found, Value: %v", lexer.get_identifier_name(l))
		case .INT, .STRING, .BOOL, .FLOAT, .NULL:
			fmt.printfln("Token: Literal found, Value: %v", lexer.get_current_token_literal(l))
		case .DO, .CONST, .NOW, .EQUALS, .OTHERWISE, .CHECK, .EVENT, .WHILE, .UNTIL, .STOP, .GO_ON :
			fmt.printfln("Token: Keyword found, Value: %v ", lexer.get_current_token_literal(l))
		case :
			fmt.printfln("Token: Symbol found, Value: %v", lexer.get_current_token_literal(l))
		}
	}
}
