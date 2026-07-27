package inputs

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import filepath "core:path/filepath"

import parser "../parser"
import display "../display"

KEYSTROKES :: enum { BACKSPACE, ENTER, CHARACTER, TAB, ESCAPE } 
keystrokes_map: map[u8]KEYSTROKES

setup_keystrokes :: proc() {
    keystrokes_map = make(map[u8]KEYSTROKES)
    keystrokes_map['\b'] = KEYSTROKES.BACKSPACE
    keystrokes_map['\x7f'] = KEYSTROKES.BACKSPACE
    keystrokes_map['\r'] = KEYSTROKES.ENTER
    keystrokes_map['\n'] = KEYSTROKES.ENTER
    keystrokes_map[9] = KEYSTROKES.TAB
    keystrokes_map[27] = KEYSTROKES.ESCAPE
}

ESCAPECMD :: enum { ESCAPE, ARROW_UP, ARROW_DOWN, ARROW_LEFT, ARROW_RIGHT, NOT_MAPPED }

Controller :: struct {
    pos: int,
    input: [dynamic]u8
}
CONTROLLER: Controller

CURRENT_HISTORY_INDEX: int
MAX_HISTORY_INDEX: int

init_input_controller :: proc() -> Controller {
    return Controller {
        pos = 0,
        input = make([dynamic]u8, context.temp_allocator)
    }
}

trim_input :: proc(input: ^string) -> string {
    trimmed := strings.clone(strings.trim_right(input^, "\n\r"), context.temp_allocator)
    return trimmed
}

read_user_keystrokes :: proc(history: ^[dynamic]string) -> string {
    buf: [1]byte
    n, _ := os.read(os.stdin, buf[:])

    char := u8(buf[0])
    //fmt.printf("[%h]\n", char)

    kind, is_special := keystrokes_map[char]

    if is_special {
        #partial switch kind {
            case .BACKSPACE:
                if len(CONTROLLER.input) > 0 && CONTROLLER.pos > 0 {
                    CONTROLLER.pos -= 1
                    ordered_remove(&CONTROLLER.input, CONTROLLER.pos)
                    fmt.printf("\b")
                    repaint_input()
                }
                return ""
            case .ENTER:
                builder: strings.Builder
                strings.builder_init(&builder, context.temp_allocator)

                for n in 0..<len(CONTROLLER.input) {
                    strings.write_byte(&builder, CONTROLLER.input[n])
                }

                result := strings.clone(strings.to_string(builder), context.temp_allocator)
                return result
            case .TAB:
                handle_tab()
                return ""
            case .ESCAPE:
                cmd := handle_escape()

                switch cmd {
                    case .ARROW_UP, .ARROW_DOWN:
                        if len(history) > 0 {
                            handle_ud_arrow(cmd, history)
                        }
                    case .ARROW_LEFT, .ARROW_RIGHT:
                            handle_lr_arrow(cmd)
                    case .ESCAPE:
                        clear_input()
                    case .NOT_MAPPED:
                }

                return ""
            }
    } else {
        fmt.printf("%c", char)

        //append(&CONTROLLER.input, char)
        add_char_to_input(&char)
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
            case 67:
                return ESCAPECMD.ARROW_RIGHT
            case 68:
                return ESCAPECMD.ARROW_LEFT
            case:
                return ESCAPECMD.NOT_MAPPED
        }
    }

    if char_one == 27 {
        return ESCAPECMD.ESCAPE
    }

    return ESCAPECMD.NOT_MAPPED
}

handle_ud_arrow :: proc(cmd: ESCAPECMD, history: ^[dynamic]string) {
    new_ch_idx := CURRENT_HISTORY_INDEX
    
    if cmd == ESCAPECMD.ARROW_UP {
        new_ch_idx -= 1
    } else if cmd == ESCAPECMD.ARROW_DOWN {
        new_ch_idx += 1
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

    clear_input()
    populate_at_index(history)
}

handle_lr_arrow :: proc(cmd: ESCAPECMD) {
    #partial switch cmd {
        case .ARROW_LEFT:
            if CONTROLLER.pos > 0 {
                fmt.printf("\b")
                CONTROLLER.pos -= 1
            }
        case .ARROW_RIGHT:
            if CONTROLLER.pos < len(CONTROLLER.input) {
                fmt.printf("\x1b[C")
                CONTROLLER.pos += 1
            }
    }
}

clear_input :: proc() {
    if len(CONTROLLER.input) == 0 {
        return
    }

    for n in 0..<len(CONTROLLER.input) {
        fmt.printf("\b \b")
    }

    clear(&CONTROLLER.input)
    CONTROLLER.pos = 0

    return
}

populate_at_index :: proc(history: ^[dynamic]string, index: int = CURRENT_HISTORY_INDEX) {
    cmd_from_history := history[index]

    for n in 0..<len(cmd_from_history) {
        char := cmd_from_history[n]
        fmt.printf("%c", char)

        append(&CONTROLLER.input, char)
    }

    CONTROLLER.pos = len(CONTROLLER.input)
}

add_char_to_input :: proc(char: ^u8) {
    inject_at(&CONTROLLER.input, CONTROLLER.pos, char^)
    CONTROLLER.pos += 1

    repaint_input()
}

repaint_input :: proc() {
    tail_len := len(CONTROLLER.input) - CONTROLLER.pos

    // reprint everything from the cursor to the end
    for n in CONTROLLER.pos..<len(CONTROLLER.input) {
        fmt.printf("%c", CONTROLLER.input[n])
    }

    // print one space to erase a leftover char (from a deletion)
    // on insertion this just paints past the end harmlessly
    fmt.printf(" ")

    // step the cursor back over the tail AND that space, landing at pos
    for i := 0; i < tail_len + 1; i += 1 {
        fmt.printf("\b")
    }
}

paint_input :: proc() {
    CONTROLLER.pos = 0

    for n in CONTROLLER.pos..<len(CONTROLLER.input) {
        fmt.printf("%c", CONTROLLER.input[n])
        CONTROLLER.pos += 1
    }
}

handle_tab :: proc() {
    builder: strings.Builder
    strings.builder_init(&builder, context.temp_allocator)

    for i := 0; i < CONTROLLER.pos; i += 1 {
        strings.write_byte(&builder, CONTROLLER.input[i])
    }

    input_as_string := strings.clone(strings.to_string(builder), context.temp_allocator)
    ss := strings.split(input_as_string, " ", context.temp_allocator)

    length := len(ss)

    if length == 1 {
        // we suppose its a command so we cycle through built ins
        results: [dynamic]string

        for key, _ in parser.builtins_map {
            if strings.has_prefix(key, ss[len(ss) - 1]) {
                append(&results, key)
            }
        }

        if len(results) == 1 {
            //here we should complete the command
            suffix := results[0][len(ss[0]):]

            for n in 0..<len(suffix){
                char := suffix[n]
                fmt.printf("%c", char)
                    add_char_to_input(&char)
                }
        } else if len(results) > 1 {
            fmt.printf("\n")
            for n in 0..<len(results) {
                fmt.println(results[n])
            }

            display.display_wd()
            paint_input()
        }

    } else if length >= 2 {
        token := ss[len(ss) - 1]
        dir_path := filepath.dir(token)
        prefix := filepath.base(token)

        possibilities: [dynamic]string

        f, oerr := os.open(dir_path)
        if oerr != nil { return }
        defer os.close(f)

        it := os.read_directory_iterator_create(f)
        defer os.read_directory_iterator_destroy(&it)

        for info in os.read_directory_iterator(&it) {
            if strings.has_prefix(info.name, prefix) && info.type == .Directory {
                append(&possibilities, strings.clone(info.name, context.temp_allocator))
            }
        }

        if len(possibilities) == 1 {
            c := possibilities[0]
            suffix := c[len(prefix):]

            for n in 0..<len(suffix){
                char := suffix[n]
                fmt.printf("%c", char)
                    add_char_to_input(&char)
                }

            fmt.printf("%c", '/')
            char : u8 = '/'
            add_char_to_input(&char)
        } else if len(possibilities) > 1 {
            fmt.printf("\n")
            for n in 0..<len(possibilities) {
                if n != len(possibilities) - 1 {
                    fmt.printf("%v, ", possibilities[n])
                } else {
                    fmt.printf("%v\n", possibilities[n])
                }
            }

            display.display_wd()
            paint_input()
        }
    }
}