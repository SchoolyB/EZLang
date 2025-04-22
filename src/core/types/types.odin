package types
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
 * File: types.odin
 * Author: Marshall A Burns
 * GitHub: @SchoolyB
 * Description: Contains all types for the EZLang compiler codebase.
 */


//List of all tokens within EZLang
Token :: enum {
	//end of file
	EOF,
	//keywords
	EQUALS,
	CONST, //used to declare a constant variable
	INFER, //implicit variabel declaration
	NOW, //used to re-assign a variables value
	PLUS, //+
	MINUS, //-
	TIMES, //*
	DIVIDE, // /
	MOD, // %
	EQUAL_TO, // ==
	NEQUAL, // !=
	GTHAN, // >
	LTHAN, // <
	GTHANEQ, // >=
	LTHANEQ, // <=
	AND, // &&
	OR, // ||
	WHILE, // while
	UNTIL, // same as a do while loop
	IF, // if
	OTHERWISE, // acts as an else statement
	EVERY, //for each
	IN, // in
	CHECK, //switch
	EVENT, //case
	STOP, //break
	GO_ON, //go-on
	DO, //used do declare a function
	RETURNS, // used to assign a functions return type e.g  >>> String
	RETURN, //used to return a value from a function
	WITH, //used to declare a function parameter
	//usual symbols
	SEMICOLON, // ;
	COLON, // :
	LCBRACE, // {
	RCBRACE, // }
	LPAREN, // (
	RPAREN, // )
	LSQBRACKET, // [
	RSQBRACKET, // ]
	COMMA, // ,
	DOT, // .
	QUOTE, // "
	APOSTROPHE, // '
	//identifiers
	IDENTIFIER,
	//types
	INT, //integer
	STRING, //string
	FLOAT, //float
	BOOL, //bool
	NULL, //nil or null
	//illegal token
	ILLEGAL,

	//standard library functions
	DISPLAY,
	DISPLAYLN,
	DISPLAYF,
	DISPLAYFLN,
}


// Lexer represents the lexical analyzer for EZLang.
// It processes the input string and breaks it down into tokens.
Lexer :: struct {
	input:           string, // The full input string to be lexically analyzed
	position:        int, // Current position in the input (points to current char)
	readPosition:   int, // Current reading position in input (after current char)
	currentChar:              byte, // Current character
	lastIdentifier: string, //last identifier read
	lastInteger:     int, //last number read
	lastString:     string, //last string read
	lastBoolean: bool,
	lastToken:      Token, //last token read
}


// Parser represents the syntactic analyzer for EZLang.
// It takes tokens from the Lexer and constructs an Abstract Syntax Tree (AST).
Parser :: struct {
	lexicon:         ^Lexer, // Pointer to the Lexer, used to get tokens
	currentToken:   Token, // The current token being processed
	peekToken:      Token, // The next token, used for lookahead
	lastIdentifier: string, // Add this field???
	lastString:     string, // Add this field???
	inFunction:     bool, // flag to indicate if we are in a function.
}

// Node is the base struct for all AST nodes.
// It contains the token associated with the node.
Node :: struct {
	token: Token, // The token associated with this node
}

// Statement is a base struct for all statement nodes in the AST.
// It embeds the Node struct to inherit its properties.
Statement :: struct {
	using node: Node,
}

// Expression is a base struct for all expression nodes in the AST.
// It embeds the Node struct to inherit its properties.
Expression :: struct {
	using node: Node,
}

// Program represents the root node of the AST.
// It contains a dynamic array of all top-level statements in the program.
Program :: struct {
	statements: [dynamic]^Statement, // All top-level statements in the program
}

// VariableDeclaration represents a variable declaration statement.
// It includes the variable name and its initial value.
VariableDeclaration :: struct {
	using stmt: Statement,
	name:       string, // The name of the variable being declared
	type:       string, // The type of the variable being declared
	value:      ^Expression, // The initial value of the variable (as an expression)
	isConst:   bool, // Flag to indicate if the variable is a constant
}

// ReassignmentStatement represents a variable reassignment statement.
// It includes the variable name and the new value being assigned.
ReassignmentStatement :: struct {
	using stmt: Statement,
	name:       string, // The name of the variable being assigned
	value:      ^Expression, // The new value being assigned (as an expression)
}

// IfStatement represents an if-else control structure.
// It includes the condition, the consequence (if true), and an optional alternative (else).
IfStatement :: struct {
	using stmt:  Statement,
	condition:   ^Expression, // The condition to be evaluated
	consequence: ^BlockStatement, // The block of code to execute if condition is true
	alternative: ^BlockStatement, // The optional else block (may be nil)
}

// WhileStatement represents a while loop control structure.
// It includes the loop condition and the body of the loop.
WhileStatement :: struct {
	using stmt: Statement,
	condition:  ^Expression, // The condition to be evaluated before each iteration
	body:       ^BlockStatement, // The body of the while loop
}

// FunctionDeclaration represents a function definition.
// It includes the function name, parameters, and body.
FunctionDeclaration :: struct {
	using stmt:     Statement,
	name:           string, // The name of the function
	parameters:     [dynamic]^Parameter, // An array of parameter names
	body:           []^BlockStatement, // The body of the function
	returnStatment: ^ReturnStatement, // The return statement of the function
}
Parameter ::struct{
    type: string,
    name: string
}


ReturnStatement :: struct {
	using stmt: Statement,
	type:       string, // The type of the return value
	value:      []^Expression, // The value(s) to return from the function
}

// BlockStatement represents a block of statements enclosed in braces.
// It contains a dynamic array of statements within the block.
BlockStatement :: struct {
	using stmt: Statement,
	statements: [dynamic]^Statement, // The statements within this block
}

// ExpressionStatement represents a statement that consists of a single expression.
// It wraps an expression to be used as a statement.
ExpressionStatement :: struct {
	using stmt: Statement,
	expression: ^Expression, // The expression being used as a statement
}

// Identifier represents a named entity in the program (e.g., variable or function name).
Identifier :: struct {
	using expr: Expression,
	value:      string, // The name of the identifier
}

// NumberLiteral represents an integer literal in the program.
NumberLiteral :: struct {
	using expr: Expression,
	value:      int, // The integer value of the literal
}

// StringLiteral represents a string literal in the program.
StringLiteral :: struct {
	using expr: Expression,
	value:      string, // The string value of the literal
}

// BooleanLiteral represents a boolean literal (true or false) in the program.
BooleanLiteral :: struct {
	using expr: Expression,
	value:      bool, // The boolean value of the literal
}

// PrefixExpression represents an expression with a unary operator.
// It includes the operator and the expression it applies to.
PrefixExpression :: struct {
	using expr: Expression,
	operator:   string, // The unary operator (e.g., "-", "!")
	right:      ^Expression, // The expression the operator is applied to
}

// InfixExpression represents an expression with a binary operator.
// It includes the left operand, operator, and right operand.
InfixExpression :: struct {
	using expr: Expression,
	left:       ^Expression, // The left operand
	operator:   string, // The binary operator (e.g., "+", "-", "*")
	right:      ^Expression, // The right operand
}

// CallExpression represents a function call.
// It includes the function being called and its arguments.
CallExpression :: struct {
	using expr: Expression,
	function:   ^Expression, // The function being called (usually an Identifier)
	arguments:  [dynamic]^Expression, // The arguments passed to the function
}
