package skidbladnir

import "core:fmt"
import "core:os"
import "core:strings"

main :: proc() {
    fmt.println("Here we are using SKIDBLADNIR")

    working := true
    
    for working {
        display_wd()

        user_input := read_user_input()
        result, cmd := parse_input(user_input)

        if cmd == "exit" {
            working = false;
            return;
        }
    }
}