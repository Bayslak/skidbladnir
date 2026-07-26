package display 

import "core:fmt"
import "core:os"
import "core:strings"

set_blinking_cursor :: proc(skid: bool) {
    if skid {
        fmt.printf("\x1b[3 q") // set the cursor to _
    } else {
        fmt.printf("\x1b[0 q") // set it back to normal |
    }
}

display_wd :: proc() {
    wd, err := os.get_working_directory(context.temp_allocator)
    folders := strings.split(wd, "/", context.temp_allocator)
    n_folders := len(folders)

    fmt.printf("%v> ", folders[n_folders - 1])
}