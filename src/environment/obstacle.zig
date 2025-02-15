const std = @import("std");

const point = @import("point.zig");

pub const Obstacle = struct {
    width: u8 = undefined,
    height: u8 = undefined,
    startPosition: point.Point,

    pub fn init(w: u8, h: u8, startPosition: point.Point) Obstacle {
        return Obstacle{
            .width = w,
            .height = h,
            .startPosition = startPosition,
        };
    }

    pub fn isPartOfObstacle(self: Obstacle, p: point.Point) bool {
        return p.x >= self.startPosition.x and
            p.x < self.startPosition.x + self.width and
            p.y >= self.startPosition.y and
            p.y < self.startPosition.y + self.height;
    }
};
