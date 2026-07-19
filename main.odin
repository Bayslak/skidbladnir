package skidbladnir

import "core:fmt"
import "core:os"
import "core:strings"

import input "./inputs"
import parser "./parser"
import display "./display"
import tracker "./memory"

main :: proc() {

    track := tracker.start_tracking()

    working := true
    
    for working {
        display.display_wd()

        user_input, valid := input.read_user_input()

        if !valid {
            break
        }

        result, cmd := parser.parse_input(user_input)

        if cmd == "exit" {
            working = false;
            return;
        }

        tracker.check_memory_usage(&track)

        free_all(context.temp_allocator)
    }
}