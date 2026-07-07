package parser

import "core:fmt"
import "core:os"
import "core:strings"

execute_command :: proc(arguments: []string) -> (result: bool, command: string) {
    process, start_err := os.process_start(os.Process_Desc{
        command = arguments,
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