package lexer

import "../types"
import "core:fmt"
import "core:strconv"
import "core:strings"
/*
 * Copyright 2024 Marshall A Burns & Solitude Software Solutions LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * File: lexer.odin
 * Author: Marshall A Burns
 * GitHub: @SchoolyB
 * Description: Parser implementation for the EZ programming language.
 * This file contains the core parsing logic that transforms tokens into
 * an abstract syntax tree (AST).
 */


new_lexer :: proc(input: string) -> ^types.Lexer {
	using types
	lexicon := new(Lexer)
	lexicon.input = input
	lexicon.position = 0
	lexicon.readPosition = 0
	read_char(lexicon)
	return lexicon
}


//Reads the next character in the input string
read_char :: proc(lexicon: ^types.Lexer) {
	if lexicon.readPosition >= len(lexicon.input) {
		lexicon.currentChar = 0 // EOF
	} else {
		lexicon.currentChar = lexicon.input[lexicon.readPosition]
	}
	lexicon.position = lexicon.readPosition
	lexicon.readPosition += 1
}

get_type_name :: proc(token: types.Token) -> string {
	#partial switch token {
	case .INT:
		return "Int"
	case .STRING:
		return "String"
	case .FLOAT:
		return "Float"
	case .BOOL:
		return "Bool"
	case .NULL:
		return "Null"
	case:
		return ""
	}
}

next_token :: proc(lexicon: ^types.Lexer) -> types.Token {
	using types
	token: Token

	for lexicon.currentChar == ' ' || lexicon.currentChar == '\t' || lexicon.currentChar == '\n' || lexicon.currentChar == '\r' {
		read_char(lexicon)
	}

	if lexicon.position >= len(lexicon.input) {
		lexicon.lastToken = .EOF
		return .EOF
	}

	switch lexicon.currentChar {
	case '=':
	   if lexicon.readPosition < len(lexicon.input) && lexicon.input[lexicon.readPosition] == '='{
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
	   if lexicon.readPosition < len(lexicon.input) && lexicon.input[lexicon.readPosition] == '>' {
	       if lexicon.readPosition + 1 < len(lexicon.input) && lexicon.input[lexicon.readPosition + 1] == '>' {
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
		token = .LPAREN
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
		lexicon.lastToken = .EOF
		return .EOF
	case '"':
		token = read_string(lexicon)
	case:
		if is_letter(lexicon.currentChar) {
			identifier := read_identifier(lexicon)
			lexicon.lastIdentifier = identifier
			token = lookup_identifier(identifier)
		} else if is_digit(lexicon.currentChar) {
			lexicon.lastInteger = read_number(lexicon)
			token = .INT
		} else {
			token = .ILLEGAL
		}
	}

	// Don't advance the character here if we've already advanced in read_identifier
	if token != .IDENTIFIER && token != .INT && token != .STRING {
		read_char(lexicon)
	}

	lexicon.lastToken = token
	return token
}

//Reads the identifier from the input string
read_identifier :: proc(lexicon: ^types.Lexer) -> string {
	start_position := lexicon.position
	for lexicon.position < len(lexicon.input) && (is_letter(lexicon.currentChar) || is_digit(lexicon.currentChar)) {
		read_char(lexicon)
	}

	// Don't advance past special characters like semicolons
	// This ensures we don't consume the semicolon as part of the identifier
	return lexicon.input[start_position:lexicon.position]
}

//Looks up the keyword in the input string
lookup_identifier :: proc(ident: string) -> types.Token {
	using types
	switch ident {
	case ";":
	   return .SEMICOLON
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
	case "Bool":
		return .BOOL
	case "Int":
		return .INT
	case "String":
		return .STRING
	case "Float":
		return .FLOAT
	case "NULL":
		return .NULL
	case ">>>":
	return .RETURNS
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
	return lexicon.lastIdentifier
}

get_current_token_literal :: proc(lexicon: ^types.Lexer) -> string {
	#partial switch lexicon.lastToken {
	case .IDENTIFIER:
		return lexicon.lastIdentifier
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
	case .RETURN:
	   return  "return"
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
	case .SEMICOLON:
	return ";"
	// Add type tokens
	case .INT:
		return "Int"
	case .STRING:
		return "String"
	case .FLOAT:
		return "Float"
	case .BOOL:
		return "Bool"
	case .NULL:
		return "Null"
	case:
		return "ERROR. INVALID TOKEN or TOKEN NOT APPLIED TO get_current_token_literal"
	}
}

read_number :: proc(lexicon: ^types.Lexer) -> int {
	start_position := lexicon.position
	for lexicon.position < len(lexicon.input) && is_digit(lexicon.currentChar) {
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
		if lexicon.currentChar == '"' || lexicon.currentChar == 0 {
			break
		}
	}
	lexicon.lastString = lexicon.input[start_position:lexicon.position]
	read_char(lexicon) // consume closing quote

	return .STRING
}
