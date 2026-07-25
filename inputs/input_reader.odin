package inputs

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

KEYSTROKES :: enum { BACKSPACE, ENTER, CHARACTER } 
keystrokes_map: map[u8]KEYSTROKES

setup_keystrokes :: proc() {
    keystrokes_map = make(map[u8]KEYSTROKES)
    keystrokes_map['\b'] = KEYSTROKES.BACKSPACE
    keystrokes_map['\x7f'] = KEYSTROKES.BACKSPACE
    keystrokes_map['\r'] = KEYSTROKES.ENTER
    keystrokes_map['\n'] = KEYSTROKES.ENTER
}

read_user_input :: proc() -> (string, bool) {
    buf: [256]byte
    n, err := os.read(os.stdin, buf[:])

    if err != nil {
        fmt.eprintln("Error reading: ", err)
        return "", false
    }

    // now i just need to recover all of the user input
    input := string(buf[:n]) // n is the number of byte written in the buffer by the read method
    trimmed := strings.clone(strings.trim_right(input, "\n\r"), context.temp_allocator) // again, I should trim by this freaking new line thing

    return trimmed, true
}

trim_input :: proc(input: ^string) -> string {
    trimmed := strings.clone(strings.trim_right(input^, "\n\r"), context.temp_allocator)
    return trimmed
}

read_user_keystrokes :: proc(builder: ^strings.Builder) -> string {
    buf: [1]byte
    n, _ := os.read(os.stdin, buf[:])

    char := u8(buf[0])

    kind, is_special := keystrokes_map[char]

    if is_special {
        #partial switch kind {
            case .BACKSPACE:
                if strings.builder_len(builder^) > 0 {
                    fmt.printf("\b \b")
                    _ = pop(&builder.buf)
                }
                return ""
            case .ENTER:
                result := strings.clone(strings.to_string(builder^), context.temp_allocator)
                return result
            }
    } else {
        strings.write_byte(builder, char)
        fmt.printf("%c", char)
    }

    return ""
}