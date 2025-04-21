package utils

import "core:fmt"

//todo: create and error type
show_critical_error :: proc(error:string) {
    fmt.println(fmt.tprintf("%sERROR: %s%s",RED,error, RESET))
}

show_warning :: proc(warning:string) {
    fmt.println(fmt.tprintf("%sWARNING: %s%s",YELLOW,warning, RESET))
}