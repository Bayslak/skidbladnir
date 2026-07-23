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
    commands: [dynamic][dynamic]string
    support_command_list := make([dynamic]string, context.temp_allocator)

    for n in 0..<len(tokens) {
        //fmt.printf("%v - %v\n", tokens[n].lexeme, tokens[n].value)

        if tokens[n].lexeme == Lexeme.PIPE {
            append(&commands, support_command_list)
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

    if len(commands) > 2 {
        fmt.println("More then 2 commands are not yet supported.")
        return false, commands[0][0]
    }

    if len(commands) == 1 {
        process, start_err := os.process_start(os.Process_Desc{
            command = commands[0][:],
            stdin = os.stdin,
            stdout = os.stdout,
            stderr = os.stderr
        })
    
        if start_err != nil {
            fmt.printf("There was a problem starting the process %v: %v\n", commands[0][0], start_err)
            return false, commands[0][0]
        }
    
        _, wait_err := os.process_wait(process)
    
        if wait_err != nil {
           fmt.printf("There was a problem waiting the process %v: %v\n", commands[0][0], wait_err)
           return false, commands[0][0]
        }
    }
    else {
        read_end, write_end, pipe_err := os.pipe()

        if pipe_err != nil {
            fmt.printf("There was a problem creating a pipe %v\n", pipe_err)
            return false, commands[0][0]
        }

        p1, p1_start_err := os.process_start(os.Process_Desc{
            command = commands[0][:],
            stdin = os.stdin,
            stdout = write_end,
            stderr = os.stderr
        })

        p2, p2_start_err := os.process_start(os.Process_Desc{
            command = commands[1][:],
            stdin = read_end,
            stdout = os.stdout,
            stderr = os.stderr
        })

        if p1_start_err != nil {
            fmt.printf("There was a problem starting the process %v: %v\n", commands[0][0], p1_start_err)
            return false, commands[0][0]
        }

        if p2_start_err != nil {
            fmt.printf("There was a problem starting the process %v: %v\n", commands[1][0], p2_start_err)
            return false, commands[1][0]
        }

        os.close(write_end)
        os.close(read_end)

        _, p1_wait_err := os.process_wait(p1)
        if p1_wait_err != nil {
           fmt.printf("There was a problem waiting the process %v: %v\n", commands[0][0], p1_wait_err)
           return false, commands[0][0]
        }

        _, p2_wait_err := os.process_wait(p2)
        if p2_wait_err != nil {
           fmt.printf("There was a problem waiting the process %v: %v\n", commands[1][0], p2_wait_err)
           return false, commands[1][0]
        }
    }

    return true, commands[0][0]
}