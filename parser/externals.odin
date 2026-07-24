package parser

import "core:fmt"
import "core:os"
import "core:strings"

execute_command :: proc(tokens: ^[dynamic]Token) -> (result: bool, command: string) {

    // uncomment this to debug arguments
    //for argument in 0..<len(arguments) {
    //    fmt.println(arguments[argument])
    //}

    // here we should check how many command there are and what they are divided by i guess
    commands, lexems := split_on_lexeme(tokens)

    switch len(commands) {
        case 1: return run_single(commands[0])
        case 2: return run_lexeme(commands, lexems[0])
        case: {
            fmt.println("More then 2 commands are not yet supported.")
            return false, commands[0][0]
        }
    }

    return true, commands[0][0]
}

split_on_lexeme :: proc(tokens: ^[dynamic]Token) -> ([dynamic][dynamic]string, [dynamic]Lexeme) {
    commands: [dynamic][dynamic]string
    lexems: [dynamic]Lexeme
    support_command_list := make([dynamic]string, context.temp_allocator)

    for n in 0..<len(tokens) {
        //fmt.printf("%v - %v\n", tokens[n].lexeme, tokens[n].value)

        if tokens[n].lexeme != Lexeme.WORD {
            append(&commands, support_command_list)
            append(&lexems, tokens[n].lexeme)
            support_command_list = make([dynamic]string, context.temp_allocator)
        }
        else if n == len(tokens) - 1 {
            append(&support_command_list, tokens[n].value)
            append(&commands, support_command_list)
        }
        else
        {
            append(&support_command_list, tokens[n].value)
        }
    }

    return commands, lexems
}

run_lexeme :: proc(commands: [dynamic][dynamic]string, lexem: Lexeme) -> (result: bool, command: string) {
    switch lexem {
        case .PIPE: return run_pipeline(commands[0], commands[1])
        case .GREATER: return run_greater(commands[0], commands[1])
        case .NONE:
        case .WORD:
        case .LESS: {
            fmt.println("Lexem not supported yet: ", lexem)
        }
    }

    return false, commands[0][0]
}

run_single :: proc(arguments: [dynamic]string) -> (result: bool, commands: string) {
    process, start_err := os.process_start(os.Process_Desc{
            command = arguments[:],
            stdin = os.stdin,
            stdout = os.stdout,
            stderr = os.stderr
        })
    
    if start_err != nil {
        fmt.printf("There was a problem starting the process %v: %v\n", arguments[0], start_err)
        return false, arguments[0]
    }
    
    _, wait_err := os.process_wait(process)
    
    if wait_err != nil {
        fmt.printf("There was a problem waiting the process %v: %v\n", arguments[0], wait_err)
        return false, arguments[0]
    }

    return true, arguments[0]
}

run_pipeline :: proc(arguments_one: [dynamic]string, arguments_two: [dynamic]string) -> (result: bool, command: string) {
    read_end, write_end, pipe_err := os.pipe()

    if pipe_err != nil {
            fmt.printf("There was a problem creating a pipe %v\n", pipe_err)
            return false, arguments_one[0]
        }

    p1, p1_start_err := os.process_start(os.Process_Desc{
        command = arguments_one[:],
        stdin = os.stdin,
        stdout = write_end,
        stderr = os.stderr
    })

    p2, p2_start_err := os.process_start(os.Process_Desc{
        command = arguments_two[:],
        stdin = read_end,
        stdout = os.stdout,
        stderr = os.stderr
    })

    if p1_start_err != nil {
        fmt.printf("There was a problem starting the process %v: %v\n", arguments_one[0], p1_start_err)
        return false, arguments_one[0]
    }

    if p2_start_err != nil {
        fmt.printf("There was a problem starting the process %v: %v\n", arguments_two[0], p2_start_err)
        return false, arguments_two[0]
    }

    os.close(write_end)
    os.close(read_end)

    _, p1_wait_err := os.process_wait(p1)
    if p1_wait_err != nil {
        fmt.printf("There was a problem waiting the process %v: %v\n", arguments_one[0], p1_wait_err)
        return false, arguments_one[0]
    }

    _, p2_wait_err := os.process_wait(p2)
    if p2_wait_err != nil {
        fmt.printf("There was a problem waiting the process %v: %v\n", arguments_two[0], p2_wait_err)
        return false, arguments_two[0]
    }

    return true, arguments_one[0]
}

run_greater :: proc(arguments_one: [dynamic]string, file_path: [dynamic]string) -> (result: bool, command: string) {
    opened_file, open_err := os.open(file_path[0], os.O_TRUNC | os.O_CREATE | os.O_WRONLY)

    if open_err != nil {
        fmt.printf("There was a problem opening %v; %v", file_path[0], open_err)
        return false, arguments_one[0]
    }

    p, p_err := os.process_start(os.Process_Desc {
      command = arguments_one[:],
      stdin = os.stdin,
      stdout = opened_file,
      stderr = os.stderr
    })

    if p_err != nil {
        fmt.printf("There was a problem; %v",  p_err)
        return false, arguments_one[0]
    }

    defer os.close(opened_file)

    _, p_wait_err := os.process_wait(p)
    if p_wait_err != nil {
        fmt.printf("There was a problem waiting the process %v: %v\n", arguments_one[0], p_wait_err)
        return false, arguments_one[0]
    }

    return true, arguments_one[0]
}