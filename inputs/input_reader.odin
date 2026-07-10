package inputs

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

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
