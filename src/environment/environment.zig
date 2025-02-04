const std = @import("std");

const agent = @import("agent.zig");
const terminal = @import("terminal.zig");

pub const Environment = struct {
    rows: u8 = 0,
    colls: u8 = 0,
    grid: [][]u8,
    agent: *agent.Agent,

    pub fn init(allocator: std.mem.Allocator, colls: u8, rows: u8) !Environment {
        const grid = try allocator.alloc([]u8, rows);
        const agt = try allocator.create(agent.Agent);

        agt.* = agent.Agent.init(0, 0, 0, 2);

        for (grid) |*row| {
            row.* = try allocator.alloc(u8, colls);
            @memset(row.*, '.');
        }

        grid[0][0] = 'A';

        return Environment{
            .grid = grid,
            .rows = rows,
            .colls = colls,
            .agent = agt,
        };
    }

    pub fn show(self: *Environment) void {
        for (self.grid) |row| {
            std.debug.print("{s}\n", .{row[0..]});
        }

        terminal.Terminal.modifyText(self.colls + 2, 0, "x=0 y=0");
    }

    pub fn moveAgent(self: *Environment, dt: f64) !void {
        self.clearPreviousPosition();
        try self.currPosition(dt);
    }

    fn currPosition(self: *Environment, dt: f64) !void {
        var buf: [9]u8 = undefined;
        var currPos = self.agent.move(
            2,
            2,
            dt,
            0.05,
        );

        if (currPos.x < 0) currPos.x = 0;
        if (currPos.x >= self.colls) currPos.x = self.colls - 1;
        if (currPos.y < 0) currPos.y = 0;
        if (currPos.y >= self.rows) currPos.y = self.rows - 1;

        self.grid[currPos.x][currPos.y] = 'A';

        const position = try std.fmt.bufPrint(
            &buf,
            "x={d} y={d}",
            .{ currPos.x, currPos.y },
        );

        terminal.Terminal.modifyText(self.colls + 2, 0, position);
        terminal.Terminal.modifyText(currPos.x, currPos.y, "A");
    }

    fn clearPreviousPosition(self: Environment) void {
        const currPos = self.agent.position();

        self.grid[currPos.x][currPos.y] = '.';
        terminal.Terminal.modifyText(currPos.x, currPos.y, ".");
    }
};
