package parser

import "../lexer"
import "../types"
import "core:fmt"
import "core:strconv"

new_parser :: proc(lexicon: ^types.Lexer) -> ^types.Parser {
	parser := new(types.Parser)
	parser.lexicon = lexicon
	// Only read the first token, we'll get peek_token when needed
	parser.current_token = lexer.next_token(parser.lexicon)
	parser.peek_token = lexer.next_token(parser.lexicon)
	// Reset back to the first token
	parser.lexicon.position = 0
	parser.lexicon.read_position = 0
	// read_char(parser.lexicon)
	parser.current_token = lexer.next_token(parser.lexicon)
	return parser
}


//parses the entire program
parse_program :: proc(p: ^types.Parser) -> ^types.Program {
	program := new(types.Program)
	program.statements = make([dynamic]^types.Statement)

	for p.current_token != .EOF {
		stmt := parse_statement(p)
		if stmt != nil {
			append(&program.statements, stmt)
		}
		p.current_token = lexer.next_token(p.lexicon)
	}

	return program
}
//parses a statement
parse_statement :: proc(p: ^types.Parser) -> ^types.Statement {
	#partial switch p.current_token {
	case .IS:
		return parse_variable_declaration(p)
	case .ENSURE:
		// fmt.println("p: ", p) //debugging
		return parse_constant_declaration(p)
	case .NOW:
		return parse_reassignment_statement(p)
	case .IF:
		return parse_if_statement(p)
	case .WHILE:
		return parse_while_statement(p)
	case .DO:
		return parse_function_declaration(p)
	case:
		return parse_expression_statement(p)
	}
}
parse_expression :: proc(parser: ^types.Parser) -> ^types.Expression {
	// For now, just parse identifiers or literals
	#partial switch parser.current_token {
	case .IDENTIFIER:
		return parse_identifier(parser)
	case .NUMBER:
		return parse_number_literal(parser)
	case .STRING:
		return parse_string_literal(parser)
	case:
		// Handle error: unexpected token
		return nil
	}
}

//looks for and parses a variable declaration
parse_variable_declaration :: proc(parser: ^types.Parser) -> ^types.Statement {
	stmt := new(types.VariableDeclaration)
	stmt.token = parser.current_token

	parser.current_token = lexer.next_token(parser.lexicon) // Consume 'IS' token might need to delete this

	if parser.current_token != .IDENTIFIER {
		return nil
	}

	stmt.name = lexer.get_identifier_name(parser.lexicon)
	parser.current_token = lexer.next_token(parser.lexicon) // Consume identifier

	if parser.current_token != .IS {
		fmt.printf("Error: Expected 'IS', got %v\n", parser.current_token)
		return nil
	}

	parser.current_token = lexer.next_token(parser.lexicon) // Consume 'IS' token

	stmt.value = parse_expression(parser)
	if stmt.value == nil {
		fmt.println("Error: Invalid expression")
		return nil
	}

	if parser.peek_token == .SEMICOLON {
		fmt.println("semicolon found")
		parser.current_token = lexer.next_token(parser.lexicon) // Consume semicolon
	}

	return stmt
}

//handles parsing constant declarations with/without explicit types.
parse_constant_declaration :: proc(parser: ^types.Parser) -> ^types.Statement {
	stmt := new(types.ConstantDeclaration)
	stmt.token = parser.current_token // ENSURE token
	// fmt.println("first token found: ", stmt.token) //debugging

	parser.current_token = lexer.next_token(parser.lexicon) // Consume 'ENSURE' token

	// Check for explicit type
	#partial switch (parser.current_token) {
	case .NUMBER, .STRING, .FLOAT, .BOOLEAN, .NOTHING:
		//consume the type token
		parser.current_token = lexer.next_token(parser.lexicon)
	case:
	//implicitly types the identifier
	// do nothing
	}

	if parser.current_token != .IDENTIFIER {
		fmt.printf("Error: Expected identifier after 'ENSURE', got %v\n", parser.current_token)
		return nil
	}

	stmt.name = lexer.get_identifier_name(parser.lexicon) // Get identifier name
	parser.current_token = lexer.next_token(parser.lexicon) // Consume identifier

	//Next check if the current token is an IS token.
	//if not throw error becuase IS is needed to assign a value
	if parser.current_token != .IS {
		fmt.printf("Error: Expected 'IS' after identifier, got %v\n", parser.current_token)
		return nil
	}

	//Consume the IS token
	parser.current_token = lexer.next_token(parser.lexicon)

	//Parse the expression that is assigned to the constant
	stmt.value = parse_expression(parser)
	if stmt.value == nil {
		fmt.println("Error: Invalid expression in constant declaration")
		return nil
	}

	//if the next token is a semicolon, consume it
	if parser.peek_token == .SEMICOLON {
		parser.current_token = lexer.next_token(parser.lexicon)
	}

	return stmt
}

//used for variable re-assignment
parse_reassignment_statement :: proc(parser: ^types.Parser) -> ^types.Statement {
	// Implementation here

	stmt := new(types.ReassignmentStatement)
	stmt.token = parser.current_token

	parser.current_token = lexer.next_token(parser.lexicon) // Consume 'NOW' token

	#partial switch parser.current_token {
	// Check for explicit type
	case .STRING, .NUMBER, .FLOAT, .BOOLEAN, .NOTHING:
		//consume the type token
		parser.current_token = lexer.next_token(parser.lexicon)
	case:
	//implicitly types the identifier
	// do nothing
	}

	if parser.current_token != .IDENTIFIER {
		fmt.printf("Error: Expected identifier after 'NOW', got %v\n", parser.current_token)
		return nil
	}

	stmt.name = lexer.get_identifier_name(parser.lexicon) // Get identifier name
	parser.current_token = lexer.next_token(parser.lexicon) // Consume identifier

	if parser.current_token != .IS {
		fmt.printf("Error: Expected 'IS' after identifier, got %v\n", parser.current_token)
		return nil
	}
	parser.current_token = lexer.next_token(parser.lexicon) // Consume 'IS' token


	stmt.value = parse_expression(parser)
	if stmt.value == nil {
		fmt.println("Error: Invalid expression in reassignment statement")
		return nil
	}


	if parser.peek_token == .SEMICOLON {
		parser.current_token = lexer.next_token(parser.lexicon)
	}

	return stmt

}

parse_if_statement :: proc(parser: ^types.Parser) -> ^types.Statement {
	return nil
}

parse_while_statement :: proc(parser: ^types.Parser) -> ^types.Statement {
	return nil
}

//functions are gonna be a bit fucky.
parse_function_declaration :: proc(parser: ^types.Parser) -> ^types.Statement {


	return nil
}

parse_expression_statement :: proc(parser: ^types.Parser) -> ^types.Statement {
	return nil
}

parse_identifier :: proc(parser: ^types.Parser) -> ^types.Expression {
	ident := new(types.Identifier)
	ident.token = parser.current_token
	ident.value = parser.lexicon.last_identifier
	parser.current_token = lexer.next_token(parser.lexicon)
	return ident
}

parse_number_literal :: proc(parser: ^types.Parser) -> ^types.Expression {
	literal := new(types.NumberLiteral)
	literal.token = parser.current_token
	literal.value = parser.lexicon.last_number
	parser.current_token = lexer.next_token(parser.lexicon)
	return literal
}

parse_string_literal :: proc(parser: ^types.Parser) -> ^types.Expression {
	literal := new(types.StringLiteral)
	literal.token = parser.current_token
	literal.value = parser.lexicon.last_string
	parser.current_token = lexer.next_token(parser.lexicon)
	return literal
}