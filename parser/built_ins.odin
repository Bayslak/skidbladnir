package parser 

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

BUILTINS :: []string{"cd", "pwd", "munin", "exit"}
builtins_map: map[string]string

setup_built_ins :: proc() {
    builtins_map = make(map[string]string)
    builtins_map["edda"] = "shows implemented built ins"
    builtins_map["cd"] = "change directory"
    builtins_map["pwd"] = "print working directory"
    builtins_map["munin"] = "print list of history commands"
    builtins_map["exit"] = "exit skidbladnir"
}

get_built_in :: proc(cmd: string) -> (exists: bool, command: string) {
    ok := cmd in builtins_map
    return ok, cmd
}

resolve_built_ins :: proc(arguments: []Token, history: ^[dynamic]string) -> (result: bool, command: string) {

    cmd := arguments[0].value
    switch cmd {
        case "edda":
            return resolve_edda()
        case "cd":
            return change_directory_built_in(arguments)
        case "pwd":
            return get_directory()
        case "munin":
            return resolve_munin(arguments, history)
        case "exit":
            return exit_shell()
    }

    return false, ""
}

resolve_edda :: proc() -> (result: bool, command: string) {
    fmt.println("In the skidbladnir shell you can find the following built ins: ")
    fmt.println()

    for key, &value in builtins_map {
        fmt.printf("%v - %v\n", key, value)
    }

    return true, "edda"
}

change_directory_built_in :: proc(arguments: []Token) -> (result: bool, command: string) {
 
    if len(arguments) != 2 {
        fmt.printf("Invalid number of arguments for built in cd.\n")
        return false, "cd"
    }

    current_directory, gwd_err := os.get_working_directory(context.temp_allocator)
    directory_to_go_to := arguments[1].value

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

resolve_munin :: proc(arguments: []Token, history: ^[dynamic]string) -> (result: bool, command: string) {
    
    len_args := len(arguments)

    switch len_args {
        case 1:
            for n in 0..<len(history) {
                fmt.printf("%d - %v\n", n, history[n])
            }
            break
        case 2:

            number, ok := strconv.parse_int(arguments[1].value)
            if number > len(history) - 1 {
                fmt.printf("The history is not that long..\n")
                return false, "munin"
            }

            if ok == false {
                fmt.printf("%d is not a valid number", arguments[1].value)
                return false, "munin"
            }

            parse_input(history[number], history)
            break
        case:
            fmt.printf("The built in munin accepts only one argument.")
            return false, "munin"
    }

    return true, "munin"
}

exit_shell :: proc() -> (result: bool, command: string) {
    return true, "exit"
}