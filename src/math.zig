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

        pub fn sub(self: Self, other: Self) Self {
            return Self.init(self.x - other.x, self.y - other.y);
        }

        pub fn mul(self: Self, s: f32) Self {
            return Self.init(self.x * s, self.y * s);
        }

        pub fn dot(self: Self, other: Self) T {
            return self.x * other.x + self.y * other.y;
        }
    };
}

pub const Vec2f = Vec2(f32);
pub const Vec2i = Vec2(i32);

// pseudo random numbers

var random_state: u32 = 0;
fn randomu32() u32 {
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

pub fn randomInRange(comptime T: type, min: T, max: T) T { //inclusive
    const range = max - min + 1;
    var result: T = randomu32() % range;
    result += min;
    return result;
}

fn randomUnilateral() f32 {
    return @intToFloat(f32, randomu32()) / @intToFloat(f32, std.math.maxInt(u32));
}

pub fn randomBilateral() f32 {
    return randomUnilateral() * 2.0 - 1.0;
}

pub const pi = std.math.pi;

pub fn cosf(angle_r: f32) f32 {
    return std.math.cos(angle_r);
}

pub fn sinf(angle_r: f32) f32 {
    return std.math.sin(angle_r);
}

pub fn truncf32(v: f32) i32 {
    return @floatToInt(i32, v);
}

pub fn ceil32(v: f32) i32 {
    return trunc_f32(std.math.ceil(v));
}

pub fn degToRad(angle: f32) f32 {
    return angle * (std.math.pi / 180.0);
}
