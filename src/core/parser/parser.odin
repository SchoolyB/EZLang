package parser

import "../lexer"
import "../types"
import "core:fmt"
import "core:strconv"
import "core:strings"
import "../../utils"

new_parser :: proc(lexicon: ^types.Lexer) -> ^types.Parser {
	parser := new(types.Parser)
	parser.lexicon = lexicon

	// Read the first two tokens
	parser.currentToken = lexer.next_token(parser.lexicon)
	parser.peekToken = lexer.next_token(parser.lexicon)

	// Reset lexer state completely
	parser.lexicon.position = 0
	parser.lexicon.readPosition = 0
	parser.lexicon.currentChar= 0
	if len(parser.lexicon.input) > 0 {
		parser.lexicon.currentChar = parser.lexicon.input[0]
	}

	// Re-read first token to get back to starting position
	parser.currentToken = lexer.next_token(parser.lexicon)

	return parser
}

//parses the entire program
parse_program :: proc(p: ^types.Parser) -> ^types.Program {
	program := new(types.Program)
	program.statements = make([dynamic]^types.Statement)

	// fmt.println("DEBUG: Starting program parse") //debugging
	for p.currentToken != .EOF {
		stmt := parse_statement(p)
		if stmt != nil {
			append(&program.statements, stmt)
			// fmt.println("DEBUG: Statement added successfully") //debugging
		} else {
			// fmt.println("DEBUG: Statement was nil") //debugging
			return nil
		}
		// Only advance token if it wasn't already advanced by the statement parser
		if p.currentToken != .EOF {
			p.currentToken = lexer.next_token(p.lexicon)
			// fmt.printf("DEBUG: Advanced to next token: %v\n", p.currentToken) //debugging
		}
	}

	return program
}
//parses a statement
parse_statement :: proc(p: ^types.Parser) -> ^types.Statement {
	#partial switch p.currentToken {
	case .DO:
		// fmt.println("p: ", p) //debugging
		return parse_function_declaration(p)
	case .INT, .STRING, .FLOAT, .BOOL, .NULL:
		// fmt.println("p: ", p) //debugging
		// if p.inFunction {
			return parse_variable_declaration(p)
		// }
	case .CONST:
		return parse_constant_declaration(p)
	case .NOW:
		return parse_reassignment_statement(p)
	case .IF:
		return parse_if_statement(p)
	case .WHILE:
		return parse_while_statement(p)
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
	#partial switch parser.currentToken {
	case .PLUS, .MINUS, .TIMES, .DIVIDE, .MOD:
		operator := parser.currentToken
		parser.currentToken = lexer.next_token(parser.lexicon)

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
	#partial switch parser.currentToken {
	case .IDENTIFIER:
		return parse_identifier(parser)
	case .INT:
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
//4 - Declared as a constant `const x is 10;`
parse_variable_declaration :: proc(parser: ^types.Parser) -> ^types.Statement {
	stmt := new(types.VariableDeclaration)
	stmt.token = parser.currentToken
	stmt.isConst = false

	// Check for explicit type
	#partial switch (parser.currentToken) {
	case .INT, .STRING, .FLOAT, .BOOL, .NULL:
		stmt.type = lexer.get_type_name(parser.currentToken)
		parser.currentToken = lexer.next_token(parser.lexicon)
		break
	case:
		// Default case assumes the type is implied
		// Dont really need this case here but I think it helps understand whats happening - Marshall
	}

	if parser.currentToken != .IDENTIFIER {
		utils.show_critical_error(fmt.tprintf("Expected identifier in variabel declartion got %v", parser.currentToken))
		return nil
	}

	   //Setting the variables name
		stmt.name = lexer.get_identifier_name(parser.lexicon)
		parser.currentToken = lexer.next_token(parser.lexicon)


		// Expect = or ;
		if parser.currentToken !=  .EQUALS && parser.currentToken != .SEMICOLON{
			utils.show_critical_error(fmt.tprintf("Expected '=' after identifier, got %v\n", parser.currentToken))
			return nil
		}

		// Handle semicolon
		if parser.currentToken == .SEMICOLON {
			parser.currentToken = lexer.next_token(parser.lexicon)
		}

fmt.println(stmt)

	return stmt
}

//handles parsing constant declarations with/without explicit types.
parse_constant_declaration :: proc(parser: ^types.Parser) -> ^types.Statement {
	stmt := new(types.VariableDeclaration)
	stmt.token = parser.currentToken //  CONST token
	// fmt.println("first token found: ", stmt.token) //debugging
	stmt.isConst = true
	parser.currentToken = lexer.next_token(parser.lexicon) // Consume 'CONST' token

	// Check for explicit type
	#partial switch (parser.currentToken) {
	case .INT, .STRING, .FLOAT, .BOOL, .NULL:
		stmt.type = lexer.get_type_name(parser.currentToken)
		parser.currentToken = lexer.next_token(parser.lexicon)
		break
	case:
		// Default case assumes the type is implied
		// Dont really need this case here but I think it helps understand whats happening - Marshall
	}

	if parser.currentToken != .IDENTIFIER {
		utils.show_critical_error(fmt.tprintf("Expected identifier in constant declaration got %v", parser.currentToken))
		return nil
	}

	//Setting the constant variables name
	stmt.name = lexer.get_identifier_name(parser.lexicon) // Get identifier name
	parser.currentToken = lexer.next_token(parser.lexicon) // Consume identifier


	//If no equals is found then constant is invalid
	if parser.currentToken != .EQUALS{
	    utils.show_critical_error("Constant declarations must have a value")
		return nil
	}

	//Consume the EQUALS token
	parser.currentToken = lexer.next_token(parser.lexicon)

	//Parse the expression that is assigned to the constant
	stmt.value = parse_expression(parser)
	   if stmt.value == nil {
			utils.show_critical_error("Invalid expression in constant declaration")
			fmt.println("Its possible there is no value assigned to constant declaration")
			return nil
	   }


	//Check for semicolon then consume it or return nil
	if semicolon_ends_statement(parser.currentToken){
	   parser.currentToken = lexer.next_token(parser.lexicon)
	}else{
	   return nil
	}

	return stmt
}

//used for variable re-assignment
parse_reassignment_statement :: proc(parser: ^types.Parser) -> ^types.Statement {
	// Implementation here
	stmt := new(types.VariableDeclaration)
	stmt.token = parser.currentToken
	if stmt.isConst {
		fmt.println("Error: Cannot reassign a constant")
		return nil
	}
	parser.currentToken = lexer.next_token(parser.lexicon) // Consume 'NOW' token

	#partial switch parser.currentToken {
	// Check for explicit type
	case .STRING, .INT, .FLOAT, .BOOL, .NULL:
		//consume the type token
		parser.currentToken = lexer.next_token(parser.lexicon)
	case:
	//implicitly types the identifier
	// do nothing
	}

	if parser.currentToken != .IDENTIFIER {
		fmt.printf("Error: Expected identifier after 'NOW', got %v\n", parser.currentToken)
		return nil
	}

	stmt.name = lexer.get_identifier_name(parser.lexicon) // Get identifier name
	parser.currentToken = lexer.next_token(parser.lexicon) // Consume identifier

	if parser.currentToken != .EQUALS {
		fmt.printf("Error: Expected 'IS' after identifier, got %v\n", parser.currentToken)
		return nil
	}
	parser.currentToken = lexer.next_token(parser.lexicon) // Consume 'IS' token

	stmt.value = parse_expression(parser)
	if stmt.value == nil {
		fmt.println("Error: Invalid expression in reassignment statement")
		return nil
	}

	// Check for semicolon in current token or peek token
	if parser.currentToken == .SEMICOLON {
		parser.currentToken = lexer.next_token(parser.lexicon)
	}
	return stmt
}


parse_function_declaration :: proc(parser: ^types.Parser) -> ^types.Statement {
	stmt := new(types.FunctionDeclaration)
	stmt.token = parser.currentToken // DO token
	parser.currentToken = lexer.next_token(parser.lexicon) // consume DO token

	// Parse function name
	if parser.currentToken != .IDENTIFIER {
		fmt.printf("Error: Expected identifier after 'do', got %v\n", parser.currentToken)
		return nil
	}
	stmt.name = lexer.get_identifier_name(parser.lexicon)
	// fmt.println(stmt.name) //debugging
	// fmt.println("parser.currentToken2: ", parser.currentToken) //debugging
	parser.currentToken = lexer.next_token(parser.lexicon)

	// Check if we need to look ahead for a left parenthesis without a space
	if parser.currentToken != .LPAREN && parser.peekToken == .LPAREN {
		parser.currentToken = lexer.next_token(parser.lexicon) // Move to the LPAREN
	}

	// Handle parameters
	if parser.currentToken == .LPAREN {
	    parser.currentToken = lexer.next_token(parser.lexicon)
	    if parser.currentToken != .RPAREN {
	        // Parse parameter list
	        stmt.parameters = parse_parameter_list(parser)
			defer delete(stmt.parameters)
	    }

	    if parser.currentToken == .RPAREN {
	        parser.currentToken = lexer.next_token(parser.lexicon) // consume )
	    } else {
	        fmt.printf("Error: Expected ')' after parameter list, got %v\n", parser.currentToken)
	        return nil
	    }
	}

	// Handle return type
	if parser.currentToken == .RETURNS {
		parser.currentToken = lexer.next_token(parser.lexicon)
		stmt.returnStatment = new(types.ReturnStatement)

		#partial switch parser.currentToken {
		case .INT, .STRING, .FLOAT, .BOOL, .NULL:
			stmt.returnStatment.type = lexer.get_type_name(parser.currentToken)
			parser.currentToken = lexer.next_token(parser.lexicon)
		case:
			fmt.printf(
				"Error: Expected return type after 'returns', got %v\n",
				parser.currentToken,
			)
			return nil
		}
	}

	// Parse function body
	parser.currentToken = lexer.next_token(parser.lexicon)
	if parser.currentToken != .LCBRACE {
		fmt.printf(
			"Error: Expected ')' after function declaration, got %v\n",
			parser.currentToken,
		)
		return nil
	}
	parser.inFunction = true
	parser.currentToken = lexer.next_token(parser.lexicon) // consume {

	// Parse statements in function body
	body_statements := make([dynamic]^types.BlockStatement)
	for parser.currentToken != .RCBRACE && parser.currentToken != .EOF {
		stmt := parse_statement(parser)
		if stmt != nil {
			// Create a new BlockStatement to wrap the regular statement
			block_stmt := new(types.BlockStatement)
			block_stmt.statements = make([dynamic]^types.Statement)
			append(&block_stmt.statements, stmt)
			append(&body_statements, block_stmt)
		}
	}
	parser.inFunction = false
	if parser.currentToken == .RCBRACE {
		parser.currentToken = lexer.next_token(parser.lexicon) // consume }
	}

	stmt.body = body_statements[:]
	return stmt
}

//ideally params would be listed like: (Number x, string y, Boolean z) type space identifier
parse_parameter_list :: proc(parser: ^types.Parser) -> [dynamic]^types.Parameter {
    parameters := make([dynamic]^types.Parameter)

    // Continue parsing parameters until we hit a closing parenthesis
    for parser.currentToken != .RPAREN && parser.currentToken != .EOF {
        param := new(types.Parameter)

        // Check for type
        #partial switch parser.currentToken {
        case .INT, .STRING, .FLOAT, .BOOL, .NULL:
            param.type = lexer.get_type_name(parser.currentToken)
            parser.currentToken = lexer.next_token(parser.lexicon)
        case:
            fmt.printf("Error: Expected parameter type, got %v\n", parser.currentToken)
            return parameters
        }

        // Check for identifier
        if parser.currentToken != .IDENTIFIER {
            fmt.printf("Error: Expected parameter name after type, got %v\n", parser.currentToken)
            return parameters
        }

        param.name = lexer.get_identifier_name(parser.lexicon)
        parser.currentToken = lexer.next_token(parser.lexicon)

        // Add parameter to list
        append(&parameters, param)

        // If next token is a comma, consume it and continue
        if parser.currentToken == .COMMA {
            parser.currentToken = lexer.next_token(parser.lexicon)
        } else if parser.currentToken != .RPAREN {
            fmt.printf("Error: Expected ',' or ')' after parameter, got %v\n", parser.currentToken)
            return parameters
        }
    }

    return parameters
}

parse_return_statement :: proc(parser: ^types.Parser) -> ^types.Statement {
	return nil
}

parse_function_call :: proc(parser: ^types.Parser) -> ^types.Statement {
	return nil
}

//if statements generally the same as other languages but instead of "elif","else if", or "elseif" EZ uses "otherwise"
parse_if_statement :: proc(parser: ^types.Parser) -> ^types.Statement {
	return nil
}

parse_while_statement :: proc(parser: ^types.Parser) -> ^types.Statement {
	return nil
}

//check statements are the same as switch statements
//check statments use the keywords "check","event","stop" as opposed to "switch","case","break"
parse_check_statement :: proc(parser: ^types.Parser) -> ^types.Statement {
	return nil
}
parse_identifier :: proc(parser: ^types.Parser) -> ^types.Expression {
	ident := new(types.Identifier)
	ident.token = parser.currentToken
	ident.value = parser.lexicon.lastIdentifier
	parser.currentToken = lexer.next_token(parser.lexicon)
	return ident
}

parse_number_literal :: proc(parser: ^types.Parser) -> ^types.Expression {
	literal := new(types.NumberLiteral)
	literal.token = parser.currentToken
	literal.value = parser.lexicon.lastNumber
	parser.currentToken = lexer.next_token(parser.lexicon)
	return literal
}

parse_string_literal :: proc(parser: ^types.Parser) -> ^types.Expression {
	literal := new(types.StringLiteral)
	literal.token = parser.currentToken
	literal.value = parser.lexicon.lastString
	parser.currentToken = lexer.next_token(parser.lexicon)
	return literal
}




//Parser Helper functions
semicolon_ends_statement :: proc(tok: types.Token) -> bool {
	   if tok != .SEMICOLON{
				utils.show_critical_error("Statement must end in a semicolon")
				return false
		}
		return true
	}