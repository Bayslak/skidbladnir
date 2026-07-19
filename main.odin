package skidbladnir

import "core:fmt"
import "core:os"
import "core:strings"
import "core:bufio"

import input "./inputs"
import parser "./parser"
import display "./display"
import tracker "./memory"


main :: proc() {

    track := tracker.start_tracking()

    working := true
    history: [dynamic]string

    for working {
        display.display_wd()

        user_input, valid := input.read_user_input()
        
        if !valid {
            break
        }
        
        result, cmd := parser.parse_input(user_input, &history)
        
        if cmd != "munin" {
            if result {
                // we do not specify the context.temp_allocator so that
                // the history can live in the heap and not get freed
                cloned_user_input := strings.clone(user_input)
                append(&history, cloned_user_input)
            }
        }
        
        if cmd == "exit" {
            working = false;
            return;
        }

        tracker.check_memory_usage(&track)

        free_all(context.temp_allocator)
    }
}