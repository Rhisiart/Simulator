const std = @import("std");
const time = std.time;
const ArenaAllocator = std.heap.ArenaAllocator;
const heap = std.heap.page_allocator;

const environment = @import("../environment/environment.zig");

pub const Simulator = struct {
    environment: *environment.Environment,
    allocator: ArenaAllocator,

    pub fn init() !Simulator {
        var arena = ArenaAllocator.init(heap);
        const allocator = arena.allocator();
        const env = try allocator.create(environment.Environment);

        env.* = try environment.Environment.init(
            allocator,
            20,
            10,
        );

        return Simulator{
            .environment = env,
            .allocator = arena,
        };
    }

    pub fn engineLoop(self: Simulator) !void {
        const dt: f64 = 0.1;
        const fps: u64 = 1;
        const frame_time_ns: u64 = time.ns_per_s / fps;

        var timer = try time.Timer.start();
        var last_time: u64 = timer.read();

        self.environment.show();

        while (true) {
            const current_time = timer.read();

            if (current_time - last_time >= frame_time_ns) {
                last_time = current_time;

                try self.environment.moveAgent(dt);
            }
        }
    }

    pub fn deinit(self: Simulator) void {
        self.allocator.deinit();
    }
};
