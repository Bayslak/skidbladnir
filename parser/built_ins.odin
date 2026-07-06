package parser 

import "core:fmt"
import "core:os"
import "core:strings"

BUILTINS :: []string{"cd", "pwd", "exit"}

get_built_in :: proc(cmd: string) -> (exists: bool, command: string) {
    for &built_in in BUILTINS {
    if built_in == cmd {
            return true, cmd
        }
    }

    return false, cmd
}

resolve_built_ins :: proc(cmd: string, arguments: []string) -> (result: bool, command: string) {

    switch cmd {
        case "cd":
            return change_directory_built_in(arguments)
        case "pwd":
            return get_directory()
        case "exit":
            return exit_shell()
    }

    return false, ""
}

change_directory_built_in :: proc(arguments: []string) -> (result: bool, command: string) {
    
    current_directory, gwd_err := os.get_working_directory(context.temp_allocator)
    directory_to_go_to := arguments[0]

    if directory_to_go_to == ".." {
        // we need to go to parent
        parent_directory := os.dir(current_directory)
        directory_to_go_to = parent_directory
    }
    
    cd_err := os.change_directory(directory_to_go_to)

    return true, "cd"
}

get_directory :: proc() -> (result: bool, command: string) {
    absolute_path, abs_err := os.get_working_directory(context.temp_allocator)
    fmt.printf("%v\n", absolute_path)
    return true, "pwd"
}

exit_shell :: proc() -> (result: bool, command: string) {
    return true, "exit"
}