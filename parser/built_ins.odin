package parser 

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import filepath "core:path/filepath"

BUILTINS :: []string{"cd", "edda", "pwd", "munin", "huginn", "bifrost", "exit"}
builtins_map: map[string]string

setup_built_ins :: proc() {
    builtins_map = make(map[string]string)
    builtins_map["edda"] = "shows implemented built ins"
    builtins_map["cd"] = "change directory"
    builtins_map["pwd"] = "print working directory"
    builtins_map["munin"] = "print list of history commands"
    builtins_map["huginn"] = "look for argument in directory, recursively"
    builtins_map["bifrost"] = "save directories path and travel to them faster"
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
        case "huginn":
            return resolve_huginn(arguments)
        case "bifrost":
            return resolve_bifrost(arguments)
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

resolve_huginn :: proc(arguments: []Token) -> (result: bool, command: string) {

    if len(arguments) < 3 {
        fmt.println("huginn command needs 2 arguments.")
        return false, arguments[0].value
    }
    search_dir(arguments[1].value, arguments[2].value)
    return true, arguments[0].value
}

search_dir :: proc(path: string, needle: string) {
    f, oerr := os.open(path)
    if oerr != nil {
        fmt.eprintfln("Could not open %s: %v", path, oerr)
        return
    }
    defer os.close(f)

    it := os.read_directory_iterator_create(f)
    defer os.read_directory_iterator_destroy(&it)

    for info in os.read_directory_iterator(&it) {
        if p, err := os.read_directory_iterator_error(&it); err != nil {
            fmt.eprintfln("Failed reading at %s: %v", p, err)
            continue
        }

        if info.type == .Directory {
            search_dir(info.fullpath, needle)   // recurse into subfolder
            continue
        }

        if info.type == .Regular {
            raw_chars, rerr := os.read_entire_file_from_path(info.fullpath, context.temp_allocator)
            if rerr != nil {
                // skip quietly
                continue
            }
            if strings.contains(string(raw_chars), needle) {
                fmt.printfln("%s", info.fullpath)
            }
        }
    }

    if p, err := os.read_directory_iterator_error(&it); err != nil {
        fmt.eprintfln("Read directory failed at %s: %v", p, err)
    }
}

resolve_bifrost :: proc(arguments: []Token) -> (result: bool, command: string) {
    path := "~/.skidbladnir_bifrost"
    expanded_conf_file := expand_word(&path)
    conf_file, oerr := os.open(expanded_conf_file, { .Create, .Read, .Write, .Append })
    if oerr != nil {
        fmt.println(oerr)
        return false, ""
    }

    arguments_length := len(arguments)

    buff: [256]u8
    length, roerr := os.read(conf_file, buff[:])
    conf := strings.clone(string(buff[:length]), context.temp_allocator)
    splitted := strings.split(conf, "__", context.temp_allocator)

    if arguments_length == 1 {
        if length == 0 {
            return false, ""
        }
        
        // print all configuration saved
        for n in 0..<len(splitted) {
            sc_split := strings.split(splitted[n], "**", context.temp_allocator)
            fmt.printf("%v**%v\n", sc_split[0], sc_split[1])
        }
    } else if arguments_length == 2 {
        // check that the second argument is present in configuration
        for n in 0..<len(splitted) {
            key_value := strings.split(splitted[n], "**", context.temp_allocator)
            if key_value[0] == arguments[1].value {
                cerr := os.change_directory(key_value[1])
                return true, ""
            }
        }
    } else if arguments_length == 4 {
        // check second argument is --set and third is a valid path
        if arguments[1].value != "--set" {
            fmt.println("Right now only --set is a valid argument for bifrost builtin.")
            return false, ""
        }

        abs_path, aerr := filepath.abs(arguments[2].value)
        
        f, oerr := os.open(abs_path)
        if oerr != nil {
            fmt.eprintfln("Could not open %s: %v", abs_path, oerr)
            return
        }
        
        os.close(f)

        builder: strings.Builder
        strings.builder_init(&builder, context.temp_allocator)

        if length > 0 {
            strings.write_string(&builder, "__")
        }

        for n in 0..<len(arguments[3].value) {
            strings.write_byte(&builder, arguments[3].value[n])
        }

        strings.write_byte(&builder, '*')
        strings.write_byte(&builder, '*')

        for n in 0..<len(abs_path) {
            strings.write_byte(&builder, abs_path[n])
        }

        new_conf := strings.clone(strings.to_string(builder), context.temp_allocator)
        _, werr := os.write_string(conf_file, new_conf[:])
    } else {
        fmt.printf("bifrost builtin need 4, 2 or no arguments\n")
        return false, ""
    }

    return true, ""
}

exit_shell :: proc() -> (result: bool, command: string) {
    return true, "exit"
}