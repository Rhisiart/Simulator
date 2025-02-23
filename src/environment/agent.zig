const std = @import("std");
const math = std.math;
const prng = std.Random.DefaultPrng;
const assert = std.debug.assert;

const point = @import("point.zig");

const SCALE = 2.0;
const Direction = enum {
    Left,
    Right,
    Up,
    Down,
};

pub const Agent = struct {
    x: f64 = 0,
    y: f64 = 0,
    theta: f64 = 0,
    rnp: prng,

    pub fn init(x: f64, y: f64, theta: f64, seed: u64) Agent {
        return Agent{
            .x = x,
            .y = y,
            .theta = theta,
            .rnp = prng.init(seed),
        };
    }

    pub fn move(self: *Agent, v: f64, omega: f64, dt: f64, noise: f64) point.Point {
        const rand = self.rnp.random().float(f64) - 0.5;
        const noise_din = noise * rand;
        const noise_theta = noise * rand / 10;

        self.x += (v + noise_din) * math.cos(self.theta) * dt;
        self.y += (v + noise_din) * math.sin(self.theta) * dt;
        self.theta += (omega + noise_theta) * dt;

        return self.position();
    }

    pub fn lawnMower(self: *Agent, direction: Direction) point.Point {
        switch (direction) {
            .Down => {
                self.y += 1;
            },
            .Up => {
                self.y -= 1;
            },
            .Left => {
                self.x -= 1;
            },
            .Right => {
                self.x += 1;
            },
        }

        return self.position();
    }

    pub fn position(self: Agent) point.Point {
        return point.Point{
            .x = @intFromFloat(std.math.clamp(self.x * SCALE, 0, 255)),
            .y = @intFromFloat(std.math.clamp(self.y * SCALE, 0, 255)),
        };
    }
};

test "move" {
    var agent = Agent.init(0, 0, 0);
    agent.move(1, 1, 1, 0.05);

    assert(agent.x == 1.05);
    assert(agent.y == 0);
    assert(agent.theta == 1.05);
}
