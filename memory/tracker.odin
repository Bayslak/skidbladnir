package memory

import "core:fmt"
import "core:os"
import "core:mem"

start_tracking :: proc() -> mem.Tracking_Allocator {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    defer mem.tracking_allocator_destroy(&track)

    context.allocator = mem.tracking_allocator(&track)
    return track
}

check_memory_usage :: proc(track: ^mem.Tracking_Allocator) {
    fmt.printf("Peak memory used: %d bytes\n", track^.peak_memory_allocated)

    if len(track^.allocation_map) > 0 {
        fmt.printf("Memory Leaks: %d allocations\n", len(track^.allocation_map))
    }

    for addr, info in track^.allocation_map {
        fmt.printf("Leak: %v bytes at %v\n", info.size, info.location)
    }
}