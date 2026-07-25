package inputs

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

KEYSTROKES :: enum { BACKSPACE, ENTER, CHARACTER, ESCAPE } 
keystrokes_map: map[u8]KEYSTROKES

setup_keystrokes :: proc() {
    keystrokes_map = make(map[u8]KEYSTROKES)
    keystrokes_map['\b'] = KEYSTROKES.BACKSPACE
    keystrokes_map['\x7f'] = KEYSTROKES.BACKSPACE
    keystrokes_map['\r'] = KEYSTROKES.ENTER
    keystrokes_map['\n'] = KEYSTROKES.ENTER
    keystrokes_map[27] = KEYSTROKES.ESCAPE
}

ESCAPECMD :: enum { ARROW_UP, ARROW_DOWN, NOT_MAPPED }

CURRENT_HISTORY_INDEX: int
MAX_HISTORY_INDEX: int

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

read_user_keystrokes :: proc(builder: ^strings.Builder, history: ^[dynamic]string) -> string {
    buf: [1]byte
    n, _ := os.read(os.stdin, buf[:])

    char := u8(buf[0])
    //fmt.printf("[%h]\n", char)

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
            case .ESCAPE:
                cmd := handle_escape()

                switch cmd {
                    case .ARROW_UP, .ARROW_DOWN:
                        handle_arrow(cmd, builder, history)
                    case .NOT_MAPPED:
                }

                return ""
            }
    } else {
        strings.write_byte(builder, char)
        fmt.printf("%c", char)
    }

    return ""
}

handle_escape :: proc() -> ESCAPECMD {
    buf: [2]byte
    m, _ := os.read(os.stdin, buf[:])
    
    char_one := u8(buf[0])
    char_two := u8(buf[1])

    //fmt.printf("[%h][%h]", char_one, char_two)

    if char_one == 91 {
        switch char_two {
            case 65:
                return ESCAPECMD.ARROW_UP
            case 66:
                return ESCAPECMD.ARROW_DOWN
            case:
                return ESCAPECMD.NOT_MAPPED
        }
    }

    return ESCAPECMD.NOT_MAPPED
}

handle_arrow :: proc(cmd: ESCAPECMD, builder: ^strings.Builder, history: ^[dynamic]string) {
    new_ch_idx := CURRENT_HISTORY_INDEX
    
    if cmd == ESCAPECMD.ARROW_UP {
        new_ch_idx += 1
    } else if cmd == ESCAPECMD.ARROW_DOWN {
        new_ch_idx -= 1
    } else {
        //not implemented
        return
    }
    
    if new_ch_idx > MAX_HISTORY_INDEX {
        CURRENT_HISTORY_INDEX = 0
    } else if new_ch_idx < 0 {
        CURRENT_HISTORY_INDEX = MAX_HISTORY_INDEX
    } else {
        CURRENT_HISTORY_INDEX = new_ch_idx
    }

    clear_input(builder)
    populate_at_index(builder, history)
}

clear_input :: proc(builder: ^strings.Builder) {
    if strings.builder_len(builder^) == 0 {
        return
    }

    sentence := strings.clone(strings.to_string(builder^), context.temp_allocator)

    for n in 0..<len(sentence) {
        fmt.printf("\b \b")
    }

    strings.builder_reset(builder)
    return
}

populate_at_index :: proc(builder: ^strings.Builder, history: ^[dynamic]string, index: int = CURRENT_HISTORY_INDEX) {
    cmd_from_history := history[index]

    for n in 0..<len(cmd_from_history) {
        char := cmd_from_history[n]
        fmt.printf("%c", char)
        strings.write_byte(builder, char)
    }
}