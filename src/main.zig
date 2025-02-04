const std = @import("std");
const arenaAllocator = std.heap.ArenaAllocator;
const heap = std.heap.page_allocator;

const lib = @import("simulator_zig_lib");

const simulator = @import("simulator/simulator.zig");

pub fn main() !void {
    const smltr = try simulator.Simulator.init();
    defer smltr.deinit();

    try smltr.engineLoop();
}
