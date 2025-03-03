const std = @import("std");
const Allocator = std.mem.Allocator;

const cell = @import("../geometry/cell.zig");
const geometry = @import("../geometry/geometry.zig");
const agent = @import("agent.zig");
const obstacle = @import("obstacle.zig");
const point = @import("point.zig");
const terminal = @import("terminal.zig");

pub const Environment = struct {
    rows: u8 = 0,
    colls: u8 = 0,
    currCellIdx: u8 = 0,
    //currSegmentIdx: u8 = 0,
    grid: [][]u8,
    agent: *agent.Agent,
    geometry: *geometry.Geometry,
    obstacles: []obstacle.Obstacle,

    pub fn init(allocator: *Allocator, colls: u8, rows: u8) !Environment {
        var grid = try allocator.alloc([]u8, rows);
        const agt = try allocator.create(agent.Agent);
        const gmt = try allocator.create(geometry.Geometry);
        const obs = try createObstacles(allocator);

        for (grid, 0..) |*row, i| {
            const rowIdx: u8 = @intCast(i);
            row.* = try allocator.alloc(u8, colls);

            for (row.*, 0..) |*ce, x| {
                const collIdx: u8 = @intCast(x);
                const c = getCell(
                    obs,
                    point.Point{ .x = collIdx, .y = rowIdx },
                );

                ce.* = c;
            }
        }

        agt.* = agent.Agent.init(0, 0, 0, 2);
        gmt.* = try geometry.Geometry.init(allocator, &grid);
        try gmt.*.boustrophedonDecomposition(colls, rows);

        grid[0][0] = 'A';

        return Environment{
            .grid = grid,
            .rows = rows,
            .colls = colls,
            .agent = agt,
            .geometry = gmt,
            .obstacles = obs,
        };
    }

    pub fn show(self: *Environment) void {
        for (self.grid) |row| {
            std.debug.print("{s}\n", .{row[0..]});
        }

        terminal.Terminal.modifyText(self.colls + 2, 0, "x=0 y=0");
    }

    pub fn moveAgent(self: *Environment) !void {
        self.clearPreviousPosition();
        try self.currPosition();
    }

    fn currPosition(self: *Environment) !void {
        var buf: [9]u8 = undefined;
        const direction = self.nextPosition();
        var currPos = self.agent.lawnMower(direction);

        //std.debug.print("New position x={d} y={d}\n", .{ currPos.x, currPos.y });

        if (currPos.x < 0) currPos.x = 0;
        if (currPos.x >= self.colls) currPos.x = self.colls - 1;
        if (currPos.y < 0) currPos.y = 0;
        if (currPos.y >= self.rows) currPos.y = self.rows - 1;

        self.grid[currPos.y][currPos.x] = 'A';

        const position = try std.fmt.bufPrint(
            &buf,
            "x={d} y={d}",
            .{ currPos.x, currPos.y },
        );

        terminal.Terminal.modifyText(self.colls + 2, 0, position);
        terminal.Terminal.modifyText(currPos.x, currPos.y, "A");
    }

    fn clearPreviousPosition(self: *Environment) void {
        const currPos = self.agent.position();
        self.grid[currPos.y][currPos.x] = '.';

        terminal.Terminal.modifyText(currPos.x, currPos.y, ".");
    }

    fn nextPosition(self: *Environment) agent.Direction {
        const currPos = self.agent.position();
        const currCell = self.geometry.cells.items[self.currCellIdx];

        if (currCell.segments.get(currPos.x)) |segments| {
            const currSegment: cell.Segment = segments.items[0];

            //std.debug.print("previous direction {}\n", .{self.agent.direction});
            if ((self.agent.direction == agent.Direction.Up) or (currPos.y == 0 and self.agent.direction == agent.Direction.Right)) {
                return if (currPos.y + 1 <= currSegment.end_y) agent.Direction.Up else agent.Direction.Down;
            } else {
                return if (currPos.y == 0) agent.Direction.Right else agent.Direction.Down;
            }
        }

        return agent.Direction.Up;
    }
};

fn createObstacles(allocator: *Allocator) ![]obstacle.Obstacle {
    const obstacles = try allocator.alloc(obstacle.Obstacle, 3);

    obstacles[0] = obstacle.Obstacle.init(3, 2, point.Point{
        .x = 6,
        .y = 2,
    });
    obstacles[1] = obstacle.Obstacle.init(1, 1, point.Point{
        .x = 6,
        .y = 6,
    });
    obstacles[2] = obstacle.Obstacle.init(4, 4, point.Point{
        .x = 12,
        .y = 3,
    });

    return obstacles;
}

fn getCell(obstacles: []obstacle.Obstacle, p: point.Point) u8 {
    var c: u8 = '.';

    for (obstacles) |obs| {
        const isPart = obs.isPartOfObstacle(p);

        if (isPart) {
            c = 'x';
            break;
        }
    }

    return c;
}
