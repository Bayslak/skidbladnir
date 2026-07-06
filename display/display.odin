package display 

import "core:fmt"
import "core:os"
import "core:strings"

display_wd :: proc() {
    wd, err := os.get_working_directory(context.temp_allocator)
    folders := strings.split(wd, "\\")
    n_folders := len(folders)

    fmt.printf("%v> ", folders[n_folders - 1])
}