const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const cell = @import("cell.zig");

const free_symbol = '.';

pub const Geometry = struct {
    grid: *[][]u8,
    allocator: *Allocator,
    cells: ArrayList(*cell.Cell),
    next_cell_id: u32 = 1,

    pub fn init(allocator: *Allocator, grid: *[][]u8) !Geometry {
        const cells = ArrayList(*cell.Cell).init(allocator.*);

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

        for (self.cells.items) |c| {
            c.deinit();
        }

        self.cells.deinit();
    }

    pub fn boustrophedonDecomposition(self: *Geometry, width: u8, height: u8) Allocator.Error!void {
        for (0..width) |x| {
            const x_int: u8 = @intCast(x);
            const curr_segments = try self.getFreeSegments(
                x_int,
                height,
            );

            //std.debug.print("------------ x axis {d} ----------------\n", .{x_int});

            //for (curr_segments.items) |seg| {
            //std.debug.print("start_y = {d} end_y = {d}\n", .{ seg.start_y, seg.end_y });
            //}

            if (x_int == 0) {
                for (curr_segments.items) |segment| {
                    try self.createNewCell(x_int, segment);
                }
            } else {
                try self.updateCells(curr_segments, x_int);
            }
        }

        for (self.cells.items) |c| {
            c.*.printSegments();
        }
    }

    fn getFreeSegments(self: *Geometry, x: u8, grid_height: u8) Allocator.Error!ArrayList(cell.Segment) {
        var segments = ArrayList(cell.Segment).init(self.allocator.*);
        var in_free_segment: bool = false;
        var start_y: u8 = 0;

        for (0..grid_height) |y| {
            const yInt: u8 = @intCast(y);

            if (self.grid.*[yInt][x] == free_symbol and !in_free_segment) {
                in_free_segment = true;
                start_y = yInt;
            } else if ((self.grid.*[yInt][x] != free_symbol or yInt == grid_height - 1) and in_free_segment) {
                const end_y = if (self.grid.*[yInt][x] != free_symbol) yInt - 1 else yInt;

                try segments.append(cell.Segment{
                    .start_y = start_y,
                    .end_y = end_y,
                });
                in_free_segment = false;
            }
        }

        return segments;
    }

    fn createNewCell(self: *Geometry, x: u8, segment: cell.Segment) !void {
        //std.debug.print("Creating a Cell {d}...\n", .{self.next_cell_id});
        var c = try self.allocator.*.create(cell.Cell);
        c.* = try cell.Cell.init(self.allocator, self.next_cell_id);
        try c.addSegment(x, segment);

        self.next_cell_id += 1;
        try self.cells.append(c);
    }

    fn updateCells(
        self: *Geometry,
        current_segments: ArrayList(cell.Segment),
        x: u8,
    ) !void {
        for (current_segments.items) |seg| {
            //std.debug.print("processing the segment start_y = {d} end_y = {d}\n", .{ seg.start_y, seg.end_y });
            var overlapping_cells = ArrayList(*cell.Cell).init(self.allocator.*);

            cells_loop: for (self.cells.items) |prev_cell| {
                var iter = prev_cell.*.segments.iterator();

                while (iter.next()) |entry| {
                    for (entry.value_ptr.items) |prev_seg| {
                        if (!(seg.end_y < prev_seg.start_y or seg.start_y > prev_seg.end_y)) {
                            //std.debug.print("the cell {d} is overlapping\n", .{prev_cell.*.id});
                            try overlapping_cells.append(prev_cell);
                            continue :cells_loop;
                        }
                    }
                }
            }

            var c: *cell.Cell = undefined;
            if (overlapping_cells.items.len == 0) {
                //std.debug.print("No overlapping cells\n", .{});
                try self.createNewCell(x, seg);
            } else if (overlapping_cells.items.len == 1) {
                //std.debug.print("One overlapping cells\n", .{});
                c = overlapping_cells.items[0];

                try c.*.addSegment(x, seg);
            } else {
                //std.debug.print("{d} overlapping cells\n", .{overlapping_cells.items.len});
                c = overlapping_cells.items[0];
                try c.*.addSegment(x, seg);

                for (1..overlapping_cells.items.len) |i| {
                    try c.*.merge(overlapping_cells.items[i]);
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
