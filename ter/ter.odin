package ter

import "core:fmt"
import "core:os"
import "core:strings"
import "core:bufio"
import posix "core:sys/posix"

ORIGINAL: posix.termios
RAWMODE: posix.termios

prepare_terminal :: proc() -> (original: posix.termios, raw: posix.termios) {
    posix.tcgetattr(0, &ORIGINAL)

    RAWMODE = ORIGINAL
    RAWMODE.c_lflag -= {.ECHO, .ICANON}

    go_to_raw_mode()
    return ORIGINAL, RAWMODE
}

go_to_raw_mode :: proc() {
    posix.tcsetattr(0, posix.TC_Optional_Action.TCSANOW, &RAWMODE)
}

go_to_original_mode :: proc() {
    posix.tcsetattr(0, posix.TC_Optional_Action.TCSANOW, &ORIGINAL)
}