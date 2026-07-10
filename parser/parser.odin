package parser 

import "core:fmt"
import "core:os"
import "core:strings"

parse_input :: proc(arguments: []string) -> (result: bool, command: string) {
    n_arguments := len(arguments)

    if len(arguments) == 0 do return

    cmd_typed := arguments[0]
    arguments_to_use: [dynamic]string
    append(&arguments_to_use, cmd_typed)

    resolve_arguments(arguments[1:n_arguments], &arguments_to_use)

    bi_exists, _ := get_built_in(cmd_typed)

    if bi_exists {
        // resolve builtins
        return resolve_built_ins(cmd_typed, arguments_to_use[1:n_arguments])
    }

    ex_result, ex_err := execute_command(&arguments_to_use)

    if !ex_result {
        fmt.printf("There was a problem executing command %v: %v\n", cmd_typed, ex_err)
        return false, cmd_typed
    }

    return false, ""
}

resolve_arguments :: proc(arguments: []string, arguments_to_return: ^[dynamic]string) -> [dynamic]string {

    start_complex_arg := false 
    builder: strings.Builder
    strings.builder_init(&builder, context.temp_allocator)

    for n in 0..<len(arguments) {
        argument := arguments[n]
        len_argument := len(argument)

        if argument[0] == '"' && !start_complex_arg {
            start_complex_arg = true
            strings.write_string(&builder, argument)
            strings.write_byte(&builder, ' ')
        } else if start_complex_arg {
            strings.write_string(&builder, argument)
            strings.write_byte(&builder, ' ')

            if argument[len_argument - 1] == '"' {
                start_complex_arg = false
                complex_arg := strings.to_string(builder)
                strings.builder_destroy(&builder)
                append(&arguments_to_return^, complex_arg)
            }
        } else {
            append(&arguments_to_return^, argument)
            strings.builder_destroy(&builder) // not so sure about this to be fair
        }
    }

    return arguments_to_return^
}