const std = @import("std");

pub const Terminal = struct {
    pub fn init() Terminal {
        return Terminal{};
    }

    pub fn modifyText(x: u8, y: u8, txt: []const u8) void {
        saveCursorPosition();
        moveCursor(x, y);
        std.debug.print("{s}", .{txt});
        restoreCursorPosition();
    }

    fn moveCursor(x: u8, y: u8) void {
        std.debug.print("\x1b[{d};{d}H", .{ y + 3, x + 1 });
    }

    fn saveCursorPosition() void {
        std.debug.print("\x1b[s", .{});
    }

    fn restoreCursorPosition() void {
        std.debug.print("\x1b[u", .{});
    }

    pub fn clear() void {
        std.debug.print("\x1b[2J", .{});
    }
};
