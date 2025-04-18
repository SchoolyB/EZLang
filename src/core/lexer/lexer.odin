package lexer

import "../types"
import "core:fmt"
import "core:strconv"
import "core:strings"


new_lexer :: proc(input: string) -> ^types.Lexer {
	using types
	lexicon := new(Lexer)
	lexicon.input = input
	lexicon.position = 0
	lexicon.read_position = 0
	read_char(lexicon)
	return lexicon
}


//Reads the next character in the input string
read_char :: proc(lexicon: ^types.Lexer) {
	if lexicon.read_position >= len(lexicon.input) {
		lexicon.ch = 0 // EOF
	} else {
		lexicon.ch = lexicon.input[lexicon.read_position]
	}
	lexicon.position = lexicon.read_position
	lexicon.read_position += 1
}

get_type_name :: proc(token: types.Token) -> string {
	#partial switch token {
	case .NUMBER:
		return "Number"
	case .STRING:
		return "String"
	case .FLOAT:
		return "Float"
	case .BOOLEAN:
		return "Boolean"
	case .NULL:
		return "Null"
	case:
		return ""
	}
}

next_token :: proc(lexicon: ^types.Lexer) -> types.Token {
	using types
	token: Token

	for lexicon.ch == ' ' || lexicon.ch == '\t' || lexicon.ch == '\n' || lexicon.ch == '\r' {
		read_char(lexicon)
	}

	if lexicon.position >= len(lexicon.input) {
		lexicon.last_token = .EOF
		return .EOF
	}

	switch lexicon.ch {
	case '=':
	   if lexicon.read_position < len(lexicon.input) && lexicon.input[lexicon.read_position] == '='{
				token = .EQUAL_TO
		}else {
		token = .EQUALS
		}
	case '+':
	   token = .PLUS
	case '-':
	   token = .MINUS
	case '*':
	   token = .TIMES
	case '/':
	   token = .DIVIDE
	case '%':
	   token = .MOD
	case '>':
	   // Check if it's a >>> token
	   if lexicon.read_position < len(lexicon.input) && lexicon.input[lexicon.read_position] == '>' {
	       if lexicon.read_position + 1 < len(lexicon.input) && lexicon.input[lexicon.read_position + 1] == '>' {
	           read_char(lexicon) // consume the second '>'
	           read_char(lexicon) // consume the third '>'
	           token = .RETURNS
	       } else {
	           token = .GTHAN
	       }
	   } else {
	       token = .GTHAN
	   }
	case ';':
		token = .SEMICOLON
	case ':':
		token = .COLON
	case '{':
		token = .LCBRACE
	case '}':
		token = .RCBRACE
	case '(':
		token = .LPAREN //todo: need to fix function declaration naming. lparen does currently only works when there is a space between the function name and the parenthesis
	case ')':
		token = .RPAREN
	case '[':
		token = .LSQBRACKET
	case ']':
		token = .RSQBRACKET
	case ',':
		token = .COMMA
	case '.':
		token = .DOT
	case 0:
		lexicon.last_token = .EOF
		return .EOF
	case '"':
		token = read_string(lexicon)
	case:
		if is_letter(lexicon.ch) {
			identifier := read_identifier(lexicon)
			lexicon.last_identifier = identifier
			token = lookup_identifier(identifier)
		} else if is_digit(lexicon.ch) {
			lexicon.last_number = read_number(lexicon)
			token = .NUMBER
		} else {
			token = .ILLEGAL
		}
	}

	read_char(lexicon)
	lexicon.last_token = token
	return token
}

//Reads the identifier from the input string
read_identifier :: proc(lexicon: ^types.Lexer) -> string {
	start_position := lexicon.position
	for lexicon.position < len(lexicon.input) && (is_letter(lexicon.ch) || is_digit(lexicon.ch)) {
		read_char(lexicon)
	}
	return lexicon.input[start_position:lexicon.position]
}

//Looks up the keyword in the input string
lookup_identifier :: proc(ident: string) -> types.Token {
	using types
	// Remove the strings.to_lower call to make keywords case-sensitive
	switch ident {
	case "=":
		return .EQUALS
	case "const":
		return .CONST
	case "now":
		return .NOW
	case "+":
		return .PLUS
	case "-":
		return .MINUS
	case "*":
		return .TIMES
	case "/":
		return .DIVIDE
	case "%":
		return .MOD
	case "==":
		return .EQUAL_TO
	case ">":
		return .GTHAN
	case "<":
		return .LTHAN
	case ">=":
		return .GTHANEQ
	case "<=":
		return .LTHANEQ
	case "and":
		return .AND
	case "or":
		return .OR
	case "while":
		return .WHILE
	case "until":
		return .UNTIL
	case "if":
		return .IF
	case "otherwise":
		return .OTHERWISE
	case "every":
		return .EVERY
	case "in":
		return .IN
	case "check":
		return .CHECK
	case "event":
		return .EVENT
	case "stop":
		return .STOP
	case "go-on":
	return .GO_ON
	case "do":
		return .DO
	case "true", "false":
		return .BOOLEAN
	case "Number":
		return .NUMBER
	case "String":
		return .STRING
	case "Float":
		return .FLOAT
	case "NULL":
		return .NULL
	case "return":
		return .RETURN
	case:
		return .IDENTIFIER
	}
}
//if the passed in char byte is a letter, return true
is_letter :: proc(ch: byte) -> bool {
	return 'a' <= ch && ch <= 'z' || 'A' <= ch && ch <= 'Z' || ch == '_'
}

//if the passed in char byte is a digit, return true
is_digit :: proc(ch: byte) -> bool {
	return '0' <= ch && ch <= '9'
}

get_identifier_name :: proc(lexicon: ^types.Lexer) -> string {
	return lexicon.last_identifier
}

get_current_token_literal :: proc(lexicon: ^types.Lexer) -> string {
	#partial switch lexicon.last_token {
	case .IDENTIFIER:
		return lexicon.last_identifier
	case .CONST:
		return "const"
	case .EQUALS:
		return "="
	case .NOW:
		return "now"
	case .DO:
		return "do"
	case .RETURNS:
		return ">>>"
	case .PLUS:
		return "+"
	case .MINUS:
		return "-"
	case .TIMES:
		return "*"
	case .DIVIDE:
		return "/"
	case .MOD:
		return "%"
	case .RPAREN:
	   return ")"
	case .LPAREN:
	   return "("
	case .RCBRACE:
	   return "}"
	case .LCBRACE:
	   return "{"
	case .RSQBRACKET:
	   return "]"
	case .LSQBRACKET:
	   return "["
	// Add type tokens
	case .NUMBER:
		return "Number"
	case .STRING:
		return "String"
	case .FLOAT:
		return "Float"
	case .BOOLEAN:
		return "Boolean"
	case .NULL:
		return "Null"
	case:
		return "ERROR. INVALID TOKEN or TOKEN NOT APPLIED TO get_current_token_literal"
	}
}

read_number :: proc(lexicon: ^types.Lexer) -> int {
	start_position := lexicon.position
	for lexicon.position < len(lexicon.input) && is_digit(lexicon.ch) {
		read_char(lexicon)
	}
	number_str := lexicon.input[start_position:lexicon.position]
	number, ok := strconv.parse_int(number_str)
	if !ok {
		// Handle error: invalid number format
		return 0
	}
	return number
}


//reads the string value from the input string and returns the string literal
read_string :: proc(lexicon: ^types.Lexer) -> types.Token {
	start_position := lexicon.position + 1
	for {
		read_char(lexicon)
		if lexicon.ch == '"' || lexicon.ch == 0 {
			break
		}
	}
	lexicon.last_string = lexicon.input[start_position:lexicon.position]
	read_char(lexicon) // consume closing quote

	return .STRING
}
