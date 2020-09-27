const std = @import("std");

// 2-D vector

fn Vec2(comptime T: type) type {
    return struct {
        const Self = @This();
        x: T,
        y: T,
        pub fn init(x: T, y: T) Self {
            return Self{ .x = x, .y = y };
        }

        pub fn add(self: Self, other: Self) Self {
            return Self.init(self.x + other.x, self.y + other.y);
        }

        pub fn mul(self: Self, s: f32) Self {
            return Self.init(self.x * s, self.y * s);
        }
    };
}

pub const Vec2f = Vec2(f32);
pub const Vec2i = Vec2(i32);

// pseudo random numbers

var random_state: u32 = 0;
fn random_u32() u32 {
    if (random_state == 0) {
        random_state = @intCast(u32, std.math.absInt(@truncate(i32, std.time.milliTimestamp())) catch 10);
    }
    var result: u32 = random_state;
    result ^= result << 13;
    result ^= result >> 17;
    result ^= result << 5;
    random_state = result;
    return result;
}

pub fn random_in_range(comptime T: type, min: T, max: T) T { //inclusive
    const range = max - min + 1;
    var result: T = random_u32() % range;
    result += min;
    return result;
}

fn random_unilateral() f32 {
    return @intToFloat(f32, random_u32()) / @intToFloat(f32, std.math.maxInt(u32));
}

pub fn random_bilateral() f32 {
    return random_unilateral() * 2.0 - 1.0;
}
