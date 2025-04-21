package utils

import "core:fmt"
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
 * File: errors.odin
 * Author: Marshall A Burns
 * GitHub: @SchoolyB
 * Description: Error handling utilities
 */


//todo: create and error type
show_critical_error :: proc(error:string,location:string) {
    fmt.println(fmt.tprintf("%sERROR occured in %s: %s%s",RED, location,error, RESET))
}

show_warning :: proc(warning:string) {
    fmt.println(fmt.tprintf("%sWARNING: %s%s",YELLOW,warning, RESET))
}

