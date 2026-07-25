package skidbladnir

import "core:fmt"
import "core:os"
import "core:strings"
import "core:bufio"
import posix "core:sys/posix"

import input "./inputs"
import parser "./parser"
import display "./display"
import tracker "./memory"
import ter "./ter"


main :: proc() {
    // setups
    parser.setup_built_ins()
    input.CONTROLLER = input.init_input_controller()
    input.setup_keystrokes()
    input.CURRENT_HISTORY_INDEX = -1

    original, raw := ter.prepare_terminal()

    track := tracker.start_tracking()

    working := true
    history: [dynamic]string

    display.display_wd()
    
    for working {
        u_inp := input.read_user_keystrokes(&history)

        if u_inp == "" {
            continue
        }

        fmt.println()
        ter.go_to_original_mode()

        trimmed := input.trim_input(&u_inp)
            
        result, cmd := parser.parse_input(u_inp, &history)
            
        if cmd != "munin" {
            // we do not specify the context.temp_allocator so that
            // the history can live in the heap and not get freed
            cloned_user_input := strings.clone(u_inp)
            append(&history, cloned_user_input)
            input.MAX_HISTORY_INDEX = len(history) - 1
            input.CURRENT_HISTORY_INDEX = input.MAX_HISTORY_INDEX + 1
        }
            
        if cmd == "exit" {
            working = false;
            return;
        }

        free_all(context.temp_allocator)

        input.clear_input()
        ter.go_to_raw_mode()
        tracker.check_memory_usage(&track)
        display.display_wd()
    }
    
    ter.go_to_original_mode()
}