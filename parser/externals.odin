package parser

import "core:fmt"
import "core:os"
import "core:strings"

Command :: struct {
    args: [dynamic]string,
    output_file: string,
    append: bool
}

SupportPipe :: struct {
    s_in: ^os.File,
    s_out: ^os.File
}

execute_command :: proc(tokens: ^[dynamic]Token) -> (result: bool, command: string) {

    // uncomment this to debug arguments
    //for argument in 0..<len(arguments) {
    //    fmt.println(arguments[argument])
    //}

    // here we should check how many command there are and what they are divided by i guess
    commands, lexems := split_on_lexeme(tokens)
    pipes := instantiate_support_pipes(commands)
    
    if len(commands) > 1 && len(pipes) != len(commands) - 1 {
        fmt.println("Something is wrong.")
        return false, ""
    }

    if len(commands) == 1 {
        _, _ = run_single(commands[0])
    }
    else {
        p_descs: [dynamic]os.Process_Desc
        processes: [dynamic]os.Process

        for n in 0..<len(commands) {
            p_desc: os.Process_Desc
            if n == 0 {
                 p_desc = get_process_desc(commands[n], w_out = pipes[n].s_out)
            } else if n > 0 && n < len(commands) - 1 {
                 p_desc = get_process_desc(commands[n], pipes[n - 1].s_in, pipes[n].s_out)
            } else {

                if commands[n].output_file != "" {
                    append := commands[n].append
                    opened_file: ^os.File

                    if commands[n].append {
                        opened_file, _ = os.open(commands[n].output_file, os.O_APPEND | os.O_CREATE | os.O_WRONLY)
                    } else {
                        opened_file, _ = os.open(commands[n].output_file, os.O_TRUNC | os.O_CREATE | os.O_WRONLY)
                    }

                    p_desc = get_process_desc(commands[n], pipes[n - 1].s_in, opened_file)
                }
                else {
                    p_desc = get_process_desc(commands[n], pipes[n - 1].s_in)
                }
            }

            append(&p_descs, p_desc)
        }

        for n in 0..<len(p_descs){
            process, err := os.process_start(p_descs[n])

            if err != nil {
                fmt.printf("There was a problem starting a process\n")
                return false, ""
            }

            append(&processes, process)
        }

        close_support_pipes(&pipes)

        for n in 0..<len(processes){
            _, err := os.process_wait(processes[n])

            if err != nil {
                fmt.printf("There was a problem waiting a process\n")
                return false, ""
            }
        }

    }

    return true, ""
}

instantiate_support_pipes :: proc(commands: [dynamic]Command) -> [dynamic]SupportPipe {
    
    pipes: [dynamic]SupportPipe
    if len(commands) == 1 {
        return pipes
    }

    for n := 0; n < len(commands) - 1; n += 1 {
        p_in, p_out, err := os.pipe()

        if err != nil {
            fmt.printf("There was a problem creating the support pipe: %v\n", err)
            return pipes
        }

        s_pipe := SupportPipe {
            s_in = p_in,
            s_out = p_out
        }
        append(&pipes, s_pipe)
    }
    return pipes
}

close_support_pipes :: proc(pipes: ^[dynamic]SupportPipe) {

    for n in 0..<len(pipes) {
        os.close(pipes[n].s_in)
        os.close(pipes[n].s_out)
    }
}

split_on_lexeme :: proc(tokens: ^[dynamic]Token) -> ([dynamic]Command, [dynamic]Lexeme) {
    commands: [dynamic]Command
    lexems: [dynamic]Lexeme
    support_command_list := make([dynamic]string, context.temp_allocator)

    for i := 0; i < len(tokens); i += 1 {
        //fmt.printf("%v - %v\n", tokens[n].lexeme, tokens[n].value)
        current_lexeme := tokens[i].lexeme

        if current_lexeme == Lexeme.PIPE {
            command := Command {
                args = support_command_list
            }

            append(&commands, command)
            append(&lexems, tokens[i].lexeme)
            support_command_list = make([dynamic]string, context.temp_allocator)
        }
        else if current_lexeme == Lexeme.GREATER || current_lexeme == Lexeme.APPEND {
            command := Command {
                args = support_command_list,
                output_file = tokens[i + 1].value,
                append = current_lexeme == Lexeme.APPEND
            }

            append(&commands, command)
            append(&lexems, tokens[i].lexeme)
            support_command_list = make([dynamic]string, context.temp_allocator)
            i += 1
        }
        else if i == len(tokens) - 1 {
            append(&support_command_list, tokens[i].value)

            command := Command {
                args = support_command_list
            }

            append(&commands, command)
        }
        else
        {
            append(&support_command_list, tokens[i].value)
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

get_process_desc :: proc(command: Command, w_in: ^os.File = os.stdin, w_out: ^os.File = os.stdout) -> os.Process_Desc {
    return os.Process_Desc {
            command = command.args[:],
            stdin = w_in,
            stdout = w_out,
            stderr = os.stderr
    }
}

run_single :: proc(command: Command, w_in: ^os.File = os.stdin, w_out: ^os.File = os.stdout) -> (result: bool, commands: string) {

    out_to_use := w_out

    if command.output_file != "" {
        opened_file: ^os.File
        if command.append {
            opened_file, _ = os.open(command.output_file, os.O_APPEND | os.O_CREATE | os.O_WRONLY)
        } else {
            opened_file, _ = os.open(command.output_file, os.O_TRUNC | os.O_CREATE | os.O_WRONLY)
        }

        out_to_use = opened_file
    }

    process, start_err := os.process_start(os.Process_Desc{
            command = command.args[:],
            stdin = w_in,
            stdout = out_to_use,
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