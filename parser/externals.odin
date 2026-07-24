package parser

import "core:fmt"
import "core:os"
import "core:strings"

Command :: struct {
    args: [dynamic]string
}

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
            return false, commands[0].args[0]
        }
    }

    return true, commands[0].args[0]
}

split_on_lexeme :: proc(tokens: ^[dynamic]Token) -> ([dynamic]Command, [dynamic]Lexeme) {
    commands: [dynamic]Command
    lexems: [dynamic]Lexeme
    support_command_list := make([dynamic]string, context.temp_allocator)

    for n in 0..<len(tokens) {
        //fmt.printf("%v - %v\n", tokens[n].lexeme, tokens[n].value)

        if tokens[n].lexeme != Lexeme.WORD {

            command := Command {
                args = support_command_list
            }

            append(&commands, command)
            append(&lexems, tokens[n].lexeme)
            support_command_list = make([dynamic]string, context.temp_allocator)
        }
        else if n == len(tokens) - 1 {
            append(&support_command_list, tokens[n].value)

            command := Command {
                args = support_command_list
            }

            append(&commands, command)
        }
        else
        {
            append(&support_command_list, tokens[n].value)
        }
    }

    return commands, lexems
}

run_lexeme :: proc(commands: [dynamic]Command, lexem: Lexeme) -> (result: bool, command: string) {
    switch lexem {
        case .PIPE: return run_pipeline(commands[0], commands[1])
        case .GREATER: return run_on_file(commands[0], commands[1], lexem)
        case .APPEND: return run_on_file(commands[0], commands[1], lexem)
        case .NONE:
        case .WORD:
        case .LESS: {
            fmt.println("Lexem not supported yet: ", lexem)
        }
    }

    return false, commands[0].args[0]
}

run_single :: proc(command: Command) -> (result: bool, commands: string) {
    process, start_err := os.process_start(os.Process_Desc{
            command = command.args[:],
            stdin = os.stdin,
            stdout = os.stdout,
            stderr = os.stderr
        })
    
    if start_err != nil {
        fmt.printf("There was a problem starting the process %v: %v\n", command.args[0], start_err)
        return false, command.args[0]
    }
    
    _, wait_err := os.process_wait(process)
    
    if wait_err != nil {
        fmt.printf("There was a problem waiting the process %v: %v\n", command.args[0], wait_err)
        return false, command.args[0]
    }

    return true, command.args[0]
}

run_pipeline :: proc(arguments_one: Command, arguments_two: Command) -> (result: bool, command: string) {
    read_end, write_end, pipe_err := os.pipe()

    if pipe_err != nil {
            fmt.printf("There was a problem creating a pipe %v\n", pipe_err)
            return false, arguments_one.args[0]
        }

    p1, p1_start_err := os.process_start(os.Process_Desc{
        command = arguments_one.args[:],
        stdin = os.stdin,
        stdout = write_end,
        stderr = os.stderr
    })

    p2, p2_start_err := os.process_start(os.Process_Desc{
        command = arguments_two.args[:],
        stdin = read_end,
        stdout = os.stdout,
        stderr = os.stderr
    })

    if p1_start_err != nil {
        fmt.printf("There was a problem starting the process %v: %v\n", arguments_one.args[0], p1_start_err)
        return false, arguments_one.args[0]
    }

    if p2_start_err != nil {
        fmt.printf("There was a problem starting the process %v: %v\n", arguments_two.args[0], p2_start_err)
        return false, arguments_two.args[0]
    }

    os.close(write_end)
    os.close(read_end)

    _, p1_wait_err := os.process_wait(p1)
    if p1_wait_err != nil {
        fmt.printf("There was a problem waiting the process %v: %v\n", arguments_one.args[0], p1_wait_err)
        return false, arguments_one.args[0]
    }

    _, p2_wait_err := os.process_wait(p2)
    if p2_wait_err != nil {
        fmt.printf("There was a problem waiting the process %v: %v\n", arguments_two.args[0], p2_wait_err)
        return false, arguments_two.args[0]
    }

    return true, arguments_one.args[0]
}

run_on_file :: proc(arguments_one: Command, file_path: Command, lexeme: Lexeme) -> (result: bool, command: string) {
    opened_file: ^os.File
    open_err: os.Error

    if lexeme == Lexeme.GREATER {
        opened_file, open_err = os.open(file_path.args[0], os.O_TRUNC | os.O_CREATE | os.O_WRONLY)
    } else if lexeme == Lexeme.APPEND {
        opened_file, open_err = os.open(file_path.args[0], os.O_APPEND | os.O_CREATE | os.O_WRONLY)
    }

    if open_err != nil {
        fmt.printf("There was a problem opening %v; %v", file_path.args[0], open_err)
        return false, arguments_one.args[0]
    }

    p, p_err := os.process_start(os.Process_Desc {
      command = arguments_one.args[:],
      stdin = os.stdin,
      stdout = opened_file,
      stderr = os.stderr
    })

    if p_err != nil {
        fmt.printf("There was a problem; %v",  p_err)
        return false, arguments_one.args[0]
    }

    defer os.close(opened_file)

    _, p_wait_err := os.process_wait(p)
    if p_wait_err != nil {
        fmt.printf("There was a problem waiting the process %v: %v\n", arguments_one.args[0], p_wait_err)
        return false, arguments_one.args[0]
    }

    return true, arguments_one.args[0]
}