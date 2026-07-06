package skidbladnir

import "core:fmt"
import "core:os"
import "core:strings"

import Input "./inputs"
import Parser "./parser"
import Display "./display"

main :: proc() {
    fmt.println("Here we are using SKIDBLADNIR")

    working := true
    
    for working {
        Display.display_wd()

        user_input := Input.read_user_input()
        result, cmd := Parser.parse_input(user_input)

        if cmd == "exit" {
            working = false;
            return;
        }
    }
}