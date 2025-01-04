package parser

import "../lexer"
import "../types"
import "core:fmt"
import "core:strconv"
import "core:strings"

new_parser :: proc(lexicon: ^types.Lexer) -> ^types.Parser {
	parser := new(types.Parser)
	parser.lexicon = lexicon

	// Read the first two tokens
	parser.current_token = lexer.next_token(parser.lexicon)
	parser.peek_token = lexer.next_token(parser.lexicon)

	// Reset lexer state completely
	parser.lexicon.position = 0
	parser.lexicon.read_position = 0
	parser.lexicon.ch = 0
	if len(parser.lexicon.input) > 0 {
		parser.lexicon.ch = parser.lexicon.input[0]
	}

	// Re-read first token to get back to starting position
	parser.current_token = lexer.next_token(parser.lexicon)

	return parser
}

//parses the entire program
parse_program :: proc(p: ^types.Parser) -> ^types.Program {
	program := new(types.Program)
	program.statements = make([dynamic]^types.Statement)

	fmt.println("DEBUG: Starting program parse")
	for p.current_token != .EOF {
		fmt.printf("DEBUG: Processing token: %v\n", p.current_token)
		stmt := parse_statement(p)
		if stmt != nil {
			append(&program.statements, stmt)
			fmt.println("DEBUG: Statement added successfully")
		} else {
			fmt.println("DEBUG: Statement was nil")
		}
		// Only advance token if it wasn't already advanced by the statement parser
		if p.current_token != .EOF {
			p.current_token = lexer.next_token(p.lexicon)
			fmt.printf("DEBUG: Advanced to next token: %v\n", p.current_token)
		}
	}

	return program
}
//parses a statement
parse_statement :: proc(p: ^types.Parser) -> ^types.Statement {
	#partial switch p.current_token {
	case .DO:
		// fmt.println("p: ", p) //debugging
		return parse_function_declaration(p)
	case .NUMBER, .STRING, .FLOAT, .BOOLEAN, .NOTHING, .IS:
		// fmt.println("p: ", p) //debugging
		if p.in_function {
			return parse_variable_declaration(p)
		}
	case .ENSURE:
		// fmt.println("p: ", p) //debugging
		return parse_constant_declaration(p)
	case .NOW:
		return parse_reassignment_statement(p)
	case .IF:
		return parse_if_statement(p)
	case .WHILE:
		return parse_while_statement(p)
	case:
		return parse_expression_statement(p)
	}
	return nil
}
//parses infix expressions such as operators between two expressions
//like 1 plus 2, 3 times 4, etc.
parse_expression :: proc(parser: ^types.Parser) -> ^types.Expression {
	left := parse_primary_expression(parser)
	if left == nil {
		return nil
	}

	// Check if there's an operator following
	#partial switch parser.current_token {
	case .PLUS, .MINUS, .TIMES, .DIVIDE, .MOD:
		operator := parser.current_token
		parser.current_token = lexer.next_token(parser.lexicon)

		right := parse_primary_expression(parser)
		if right == nil {
			return nil
		}

		infix := new(types.InfixExpression)
		infix.token = operator
		infix.left = left
		infix.right = right
		infix.operator = lexer.get_current_token_literal(parser.lexicon)
		return infix
	}

	return left
}

//parses primary expressions like identifiers, numbers, and strings
parse_primary_expression :: proc(parser: ^types.Parser) -> ^types.Expression {
	#partial switch parser.current_token {
	case .IDENTIFIER:
		return parse_identifier(parser)
	case .NUMBER:
		return parse_number_literal(parser)
	case .STRING:
		fmt.println("string literal primary expression found") //debugging
		return parse_string_literal(parser)
	case:
		// Handle error: unexpected token
		return nil
	}
}
//looks for and parses a variable declaration
//Variables can be declare in many ways.
//1 - Explicitly typed without a value assigned`number x;`
//2 - Typed or untyped with a value assigned `number x is 10;` or `x is 10;`
//3 - Declared before hand then re-assigned later `number x; x is 10;` or `number x is; now x is 10;`
//4 - Declared as a constant `ensure x is 10;`
parse_variable_declaration :: proc(parser: ^types.Parser) -> ^types.Statement {
	stmt := new(types.VariableDeclaration)
	stmt.token = parser.current_token

	fmt.printf("DEBUG: Starting variable declaration with token: %v\n", parser.current_token)

	// Handle type-first declarations
	if parser.current_token == .NUMBER ||
	   parser.current_token == .STRING ||
	   parser.current_token == .FLOAT ||
	   parser.current_token == .BOOLEAN ||
	   parser.current_token == .NOTHING {
		stmt.type = lexer.get_type_name(parser.current_token)
		parser.current_token = lexer.next_token(parser.lexicon)
		fmt.printf("DEBUG: After type token, current token is: %v\n", parser.current_token)

		// After type, expect identifier
		if parser.current_token != .IDENTIFIER {
			fmt.printf("Error: Expected identifier after type, got %v\n", parser.current_token)
			return nil
		}

		stmt.name = lexer.get_identifier_name(parser.lexicon)
		parser.current_token = lexer.next_token(parser.lexicon)
		fmt.printf("DEBUG: After identifier, current token is: %v\n", parser.current_token)

		// Expect IS
		if parser.current_token != .IS {
			fmt.printf("Error: Expected 'IS' after identifier, got %v\n", parser.current_token)
			return nil
		}

		parser.current_token = lexer.next_token(parser.lexicon)
		fmt.printf("DEBUG: After IS token, current token is: %v\n", parser.current_token)

		// Parse the expression after IS
		stmt.value = parse_expression(parser)
		if stmt.value == nil {
			fmt.println("Error: Invalid expression")
			return nil
		}

		// Handle semicolon
		if parser.current_token == .SEMICOLON {
			parser.current_token = lexer.next_token(parser.lexicon)
			fmt.printf("DEBUG: After semicolon, current token is: %v\n", parser.current_token)
		}

		return stmt
	}

	fmt.printf("Error: Expected type declaration, got %v\n", parser.current_token)
	return nil
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


//functions are gonna be a bit fucky.
parse_function_declaration :: proc(parser: ^types.Parser) -> ^types.Statement {
	stmt := new(types.FunctionDeclaration)
	stmt.token = parser.current_token // DO token
	parser.current_token = lexer.next_token(parser.lexicon) // consume DO token

	// Parse function name
	if parser.current_token != .IDENTIFIER {
		fmt.printf("Error: Expected identifier after 'do', got %v\n", parser.current_token)
		return nil
	}
	stmt.name = lexer.get_identifier_name(parser.lexicon)
	parser.current_token = lexer.next_token(parser.lexicon)

	// Handle parameters
	if parser.current_token == .LPAREN {
		parser.current_token = lexer.next_token(parser.lexicon)
		if parser.current_token != .RPAREN {
			// Parse parameter list if needed
			// ... parameter parsing code ...
		}
		parser.current_token = lexer.next_token(parser.lexicon) // consume )
	}

	// Handle return type
	if parser.current_token == .RETURNS {
		parser.current_token = lexer.next_token(parser.lexicon)
		stmt.returnStatment = new(types.ReturnStatement)

		#partial switch parser.current_token {
		case .NUMBER, .STRING, .FLOAT, .BOOLEAN, .NOTHING:
			stmt.returnStatment.type = lexer.get_type_name(parser.current_token)
			parser.current_token = lexer.next_token(parser.lexicon)
		case:
			fmt.printf(
				"Error: Expected return type after 'returns', got %v\n",
				parser.current_token,
			)
			return nil
		}
	}

	// Parse function body
	if parser.current_token != .LBRACE {
		fmt.printf(
			"Error: Expected '{' after function declaration, got %v\n",
			parser.current_token,
		)
		return nil
	}
	parser.in_function = true
	parser.current_token = lexer.next_token(parser.lexicon) // consume {

	// Parse statements in function body
	body_statements := make([dynamic]^types.BlockStatement)
	for parser.current_token != .RBRACE && parser.current_token != .EOF {
		stmt := parse_statement(parser)
		if stmt != nil {
			// Create a new BlockStatement to wrap the regular statement
			block_stmt := new(types.BlockStatement)
			block_stmt.statements = make([dynamic]^types.Statement)
			append(&block_stmt.statements, stmt)
			append(&body_statements, block_stmt)
		}
	}
	parser.in_function = false
	if parser.current_token == .RBRACE {
		parser.current_token = lexer.next_token(parser.lexicon) // consume }
	}

	stmt.body = body_statements[:]
	return stmt
}

parse_parameter_list :: proc(parser: ^types.Parser) -> ^types.Expression {
	return nil
}

parse_return_type :: proc(parser: ^types.Parser) -> ^types.Statement {
	return nil
}

parse_return_statement :: proc(parser: ^types.Parser) -> ^types.Statement {
	return nil
}

parse_function_call :: proc(parser: ^types.Parser) -> ^types.Statement {
	return nil
}

parse_if_statement :: proc(parser: ^types.Parser) -> ^types.Statement {
	return nil
}

parse_while_statement :: proc(parser: ^types.Parser) -> ^types.Statement {
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
