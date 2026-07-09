package parser 

import "core:fmt"
import "core:os"
import "core:strings"

parse_input :: proc(arguments: []string) -> (result: bool, command: string) {
    n_arguments := len(arguments)

    if len(arguments) == 0 do return

    bi_exists, cmd := get_built_in(arguments[0])

    if bi_exists {
        // resolve builtins
        return resolve_built_ins(cmd, arguments[1:n_arguments])
    }

    ex_result, ex_err := execute_command(arguments)

    if !ex_result {
        fmt.printf("There was a problem executing command %v: %v\n", arguments[0], ex_err)
        return false, arguments[0]
    }

    return false, ""
}