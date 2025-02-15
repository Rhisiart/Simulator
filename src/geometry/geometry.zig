const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoArrayHashMap;

const point = @import("../environment/point.zig");

const algorithms = enum { boustrophedon_decomposition };
const free_symbol = '.';

const Segment = struct {
    start_y: u8,
    end_y: u8,
};

const Cell = struct {
    allocator: *Allocator,
    id: u32,
    segments: AutoHashMap(u8, ArrayList(Segment)),
    min_x: u8 = 0,
    max_x: u8 = 0,
    min_y: u8 = 0,
    max_y: u8 = 0,

    pub fn init(allocator: *Allocator, id: u32) !Cell {
        const segments = AutoHashMap(u8, ArrayList(Segment)).init(allocator.*);

        return Cell{
            .allocator = allocator,
            .id = id,
            .segments = segments,
        };
    }

    pub fn addSegment(self: *Cell, x: u8, segment: Segment) !void {
        if (self.segments.getPtr(x)) |segments| {
            std.debug.print("Before append, segment count in cell {d}: {d}\n", .{ self.id, segments.items.len });
            try segments.append(segment);
            std.debug.print("After append, segment count in cell {d}: {d}\n", .{ self.id, segments.items.len });
        } else {
            var new_segment = ArrayList(Segment).init(self.allocator.*);
            try new_segment.append(segment);
            try self.segments.put(x, new_segment);
        }

        if (x < self.min_x) self.min_x = x;
        if (x > self.max_x) self.max_x = x;
        if (segment.start_y < self.min_y) self.min_y = segment.start_y;
        if (segment.end_y > self.max_y) self.max_y = segment.end_y;
    }

    pub fn merge(self: *Cell, other: *Cell) !void {
        var iter = other.segments.iterator();

        while (iter.next()) |entry| {
            if (self.segments.getPtr(entry.key_ptr.*)) |segments| {
                try segments.appendSlice(entry.value_ptr.*.items);
            } else {
                try self.segments.put(entry.key_ptr.*, entry.value_ptr.*);
            }
        }

        if (other.min_x < self.min_x) self.min_x = other.min_x;
        if (other.max_x > self.max_x) self.max_x = other.max_x;
        if (other.min_y < self.min_y) self.min_y = other.min_y;
        if (other.max_y > self.max_y) self.max_y = other.max_y;
    }

    pub fn deinit(self: *Cell) void {
        var iter = self.segments.iterator();

        while (iter.next()) |entry| {
            entry.value_ptr.*.deinit();
        }

        self.segments.deinit();
    }

    pub fn printSegments(self: *Cell) void {
        std.debug.print("Segments count in cell {d}: {d}\n", .{ self.id, self.segments.count() });
        var iterator = self.segments.iterator();

        while (iterator.next()) |entry| {
            std.debug.print("-------- Cell {d} ----------\n", .{self.id});
            std.debug.print("x axis = {d} has this segments:\n", .{entry.key_ptr.*});

            for (entry.value_ptr.*.items) |segment| {
                std.debug.print("start_y = {d} end_y = {d}\n", .{ segment.start_y, segment.end_y });
            }
        }
    }
};

pub const Geometry = struct {
    grid: [][]u8,
    allocator: *Allocator,
    cells: ArrayList(*Cell),
    next_cell_id: u32 = 1,

    pub fn init(allocator: *Allocator) !Geometry {
        const grid = try allocator.alloc([]u8, 8);
        const cells = ArrayList(*Cell).init(allocator.*);

        for (grid) |*row| {
            row.* = try allocator.alloc(u8, 6);
            @memset(row.*, '.');
        }

        grid[2][3] = 'x';
        grid[2][2] = 'x';
        grid[3][3] = 'x';
        grid[3][2] = 'x';
        grid[0][4] = 'x';
        grid[0][5] = 'x';
        grid[1][4] = 'x';
        grid[1][5] = 'x';
        grid[2][4] = 'x';
        grid[2][5] = 'x';
        grid[3][4] = 'x';
        grid[3][5] = 'x';
        grid[7][2] = 'x';
        grid[7][3] = 'x';
        grid[7][4] = 'x';
        grid[6][2] = 'x';
        grid[6][3] = 'x';
        grid[6][4] = 'x';

        return Geometry{
            .grid = grid,
            .cells = cells,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Geometry) void {
        for (self.grid) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.grid);

        for (self.cells.items) |*cell| {
            cell.deinit();
        }

        self.cells.deinit();
    }

    pub fn boustrophedonDecomposition(self: *Geometry, width: u8, height: u8) Allocator.Error!void {
        for (0..width - 5) |x| {
            const x_int: u8 = @intCast(x);
            const curr_segments = try self.getFreeSegments(x_int, height);

            std.debug.print("------------ x axis {d} ----------------\n", .{x_int});

            for (curr_segments.*.items) |seg| {
                std.debug.print("start_y = {d} end_y = {d}\n", .{ seg.start_y, seg.end_y });
            }

            if (x_int == 0) {
                for (curr_segments.items) |segment| {
                    try self.createNewCell(x_int, segment);
                }
            } //else {
            // try self.updateCells(curr_segments, x_int);
            //}
        }

        for (self.cells.items) |cell| {
            cell.*.printSegments();
        }
    }

    fn getFreeSegments(self: *Geometry, x: u8, grid_height: u8) Allocator.Error!*ArrayList(Segment) {
        var segments = ArrayList(Segment).init(self.allocator.*);
        var in_free_segment: bool = false;
        var start_y: u8 = 0;

        for (0..grid_height) |y| {
            const yInt: u8 = @intCast(y);

            if (self.grid[yInt][x] == free_symbol and !in_free_segment) {
                in_free_segment = true;
                start_y = yInt;
            } else if ((self.grid[yInt][x] != free_symbol or yInt == grid_height - 1) and in_free_segment) {
                const end_y = if (self.grid[yInt][x] != free_symbol) yInt - 1 else yInt;

                try segments.append(Segment{
                    .start_y = start_y,
                    .end_y = end_y,
                });
                in_free_segment = false;
            }
        }

        return &segments;
    }

    fn createNewCell(self: *Geometry, x: u8, segment: Segment) !void {
        std.debug.print("Creating a Cell {d}...\n", .{self.next_cell_id});
        var cell = try Cell.init(self.allocator, self.next_cell_id);
        try cell.addSegment(x, segment);

        self.next_cell_id += 1;
        try self.cells.append(&cell);
    }

    fn updateCells(
        self: *Geometry,
        current_segments: ArrayList(Segment),
        x: u8,
    ) !void {
        for (current_segments.items) |seg| {
            var overlapping_cells = ArrayList(*Cell).init(self.allocator.*);
            //defer overlapping_cells.deinit();

            for (self.cells.items) |prev_cell| {
                var iter = prev_cell.*.segments.iterator();

                while (iter.next()) |entry| {
                    for (entry.value_ptr.items) |prev_seg| {
                        if (!(seg.end_y < prev_seg.start_y or seg.start_y > prev_seg.end_y)) {
                            try overlapping_cells.append(prev_cell);
                        }
                    }
                }
            }

            var cell: *Cell = undefined;
            if (overlapping_cells.items.len == 0) {
                cell = try self.createNewCell(x, seg);
                try self.cells.append(cell);
            } else if (overlapping_cells.items.len == 1) {
                cell = overlapping_cells.items[0];

                try cell.*.addSegment(x, seg);
            } else {
                //std.debug.print("multiples overlapping\n", .{});
                cell = overlapping_cells.items[0];
                try cell.*.addSegment(x, seg);

                for (1..overlapping_cells.items.len) |i| {
                    //var i_u8: u8 = @intCast(i);
                    try cell.*.merge(overlapping_cells.items[i]);
                }
            }
        }
    }
};

test "boustrophedon" {
    const ArenaAllocator = std.heap.ArenaAllocator;
    const heap = std.heap.page_allocator;
    var arena = ArenaAllocator.init(heap);
    var allocator = arena.allocator();
    defer arena.deinit();

    var geometry = try Geometry.init(&allocator);
    //defer geometry.deinit();

    try geometry.boustrophedonDecomposition(6, 8);
}
