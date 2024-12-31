# EZLang Programming Language Specification
A programming language designed to be as close to plain English as possible.

## 1. Basic Syntax Rules
- Statements end with semicolons (;)
- Code blocks are enclosed in curly braces { }
- Case-insensitive keywords
- Comments start with //

## 2. Data Types
| Type      | Description            | Example                |
| --------- | ---------------------- | ---------------------- |
| Number    | Integer values         | `number x is 42;`      |
| Decimal   | Floating-point numbers | `decimal x is 3.14;`   |
| Character | Single character       | `character x is 'A';`  |
| String    | Text sequence          | `string x is "Hello";` |
| Boolean   | True/false value       | `boolean x is true;`   |
| Nothing   | Null value             | `x is nothing;`        |

## 3. Variable Declaration and Assignment
### Variable Declaration
```
// Implicit typing
x is 0;

// Explicit typing
Number x;
Number x is 0;

// Constants
Ensure x is 0;
Ensure Number x;
Ensure Number x is 0;
```

### Variable Reassignment
```
now x is 1;
```

## 4. Operators

### Arithmetic Operators
| Keyword | Symbol | Example      |
| ------- | ------ | ------------ |
| plus    | +      | `x plus y`   |
| minus   | -      | `x minus y`  |
| times   | *      | `x times y`  |
| divide  | /      | `x divide y` |
| mod     | %      | `x mod y`    |

### Comparison Operators
| Keyword         | Symbol | Example               |
| --------------- | ------ | --------------------- |
| equal       | ==     | `x equal y`          |
| nequal      | !=     | `x nequals y`      |
| gthan       | >      | `x gthan y`           |
| lthan       | <      | `x lthan y`           |
| gthaneq | >= | `x gthane y` |
| lthaneq | <= | `x lthane y` |

### Logical Operators
| Keyword | Symbol | Example   |
| ------- | ------ | --------- |
| and     | &&     | `x and y` |
| or      | \|\|   | `x or y`  |

## 5. Control Structures

### Conditional Statements
```
if (condition) {
    // code
}
if not (condition) {
    // code
}
otherwise {
    // code
}
```

### Loops
```
// While loop
while (condition) {
    // code
}

// Do-while loop
until (condition) {
    // code
}

// For loop
for (initialization; condition; increment) {
    // code
}

// For-each loop
for every item in collection {
    // code
}
```

### Switch Statements
```
check (variable) {
    event value1 {
        // code
        stop;
    }
    event value2 {
        // code
        go-on;
    }
}
```

## 6. Functions

### Function Declaration
```
// No parameters, no return
do functionName(){
    // code
}

// With parameters, no return
do functionName(type param1, type param2) {
    // code
}

// With parameters and return
do functionName(type param1, type param2) returns returnType {
    // code
    return returnValue;
}


do int functionName() {
    // code
    return 0;
}
```

### Function Calls
```
// No parameters
functionName;

// With parameters
functionName(param1, param2);

// With return value
result is functionName(param1, param2);

// Multiple return values
result1, result2 is functionName(param1, param2);
```

## 7. Example Program
```
#import "io.ez"

number a is 5;
number b is 10;

do main() returns number {
    result is add with (a, b);
    display(result);  // output: 20
    return result;
}

do add(number x, number y) returns number {
    number total is x plus y;

    if (total equals 15) {
        total is now 20;
    }

    check (total) {
        event 20:
            display("Total is 20");
            stop;
        event 25:
            display("Total is 25");
            stop;
    }

    while (total lthan 20) {
        total is now total plus 1;
    }

    send total;
}
```