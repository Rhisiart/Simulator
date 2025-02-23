const std = @import("std");
const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;

pub const Segment = struct {
    start_y: u8,
    end_y: u8,
};

pub const Cell = struct {
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
        //std.debug.print("Inserting segment at x = {d} into the cell {d}\n", .{ x, self.id });
        //std.debug.print("Current segment count before insert: {}\n", .{self.segments.count()});

        if (self.segments.getPtr(x)) |segments| {
            try segments.append(segment);
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
        //std.debug.print("Merging the cell {d} into cell {d} \n", .{ self.id, other.id });
        var iter = other.segments.iterator();

        while (iter.next()) |entry| {
            //std.debug.print("segment {d} merging \n", .{entry.key_ptr.*});
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
        std.debug.print("-------- Cell {d} ----------\n", .{self.id});
        std.debug.print("Segments {d}\n", .{self.segments.count()});
        var iterator = self.segments.iterator();

        while (iterator.next()) |entry| {
            std.debug.print("x axis = {d} has this segments:\n", .{entry.key_ptr.*});

            for (entry.value_ptr.*.items) |segment| {
                std.debug.print("start_y = {d} end_y = {d}\n", .{ segment.start_y, segment.end_y });
            }
        }
    }
};
