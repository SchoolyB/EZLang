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
	case ';':
		token = .SEMICOLON
	case ':':
		token = .COLON
	case '{':
		token = .LBRACE
	case '}':
		token = .RBRACE
	case '(':
		token = .LPAREN
	case ')':
		token = .RPAREN
	case '[':
		token = .LBRACKET
	case ']':
		token = .RBRACKET
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
	switch strings.to_lower(ident) {
	case "is":
		return .IS
	case "ensure":
		return .ENSURE
	case "now":
		return .NOW
	case "plus":
		return .PLUS
	case "minus":
		return .MINUS
	case "times":
		return .TIMES
	case "divide":
		return .DIVIDE
	case "mod":
		return .MOD
	case "equals":
		return .EQUALS
	case "not":
		return .NOT
	case "gthan":
		return .GTHAN
	case "lthan":
		return .LTHAN
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
	case "do":
		return .DO
	case "give":
		return .GIVE
	case "true", "false":
		return .BOOLEAN
	case "number":
		return .NUMBER
	case "string":
		return .STRING
	case "float":
		return .FLOAT
	case "nothing":
		return .NOTHING
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
	case .ENSURE:
		return "ensure"
	case .NOW:
		return "now"
	case .IS:
		return "is"
	case .NUMBER:
		if lexicon.last_number == 0 {
			return "Type 'number' or value '0'"
		}
		// todo: not a huge deal but when a var/const is declared with explicit type,
		//the return value of the token 'number' literally returns the number 0.
		return fmt.tprintf("%d", lexicon.last_number)
	case .STRING:
		if lexicon.last_string == "" {
			return "Type 'string' or value ''"
		}
		//todo: same thing as above, but with strings
		return lexicon.last_string
	case .QUOTE:
		return fmt.tprintf("%c", lexicon.ch)
	case:
		// return fmt.tprintf("%c", lexicon.ch)
		return "ERROR"
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
