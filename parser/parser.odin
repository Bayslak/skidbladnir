package parser 

import "core:fmt"
import "core:os"
import "core:strings"

parse_input :: proc(input: string) -> (result: bool, command: string) {
    arguments := strings.split(input, " ")
    n_arguments := len(arguments)

    exists, cmd := get_built_in(arguments[0])

    if exists {
        // resolve builtins
        return resolve_built_ins(cmd, arguments[1:n_arguments])
    }

    return false, ""
}