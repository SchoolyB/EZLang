package std

import "core:fmt"

//prints the arguments to the console, each separated by a space
display :: proc(args: ..any) {
	for arg, i in args {
		fmt.print(arg)
		if i < len(args) - 1 {
			fmt.print(" ")
		}
	}
}

//prints the arguments to the console, followed by a newline
displayln :: proc(args: ..any) {
	display(..args)
	display("\n")
}

//prints the arguments to the console, using the format string
displayf :: proc(format: string, args: ..any) {
	fmt.printf(format, ..args)
}

//prints the arguments to the console, using the format string, followed by a newline
displayfln :: proc(format: string, args: ..any) {
	displayf(format, ..args)
	display("\n")
}
