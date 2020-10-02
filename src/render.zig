const common = @import("./platform_common.zig");
const math = @import("./math.zig");
const Vec2f = math.Vec2f;
const Vec2i = math.Vec2i;
const GameRenderBuffer = common.GameRenderBuffer;

const scale: f32 = 0.01;

pub fn clearScreen(buffer: GameRenderBuffer, color: u32) void {
    for (buffer.memory) |*pixel| {
        pixel.* = color;
    }
}

pub fn drawRect(buffer: GameRenderBuffer, p: Vec2f, half_size: Vec2f, color: u32) void {
    const aspect_multiplier = calculateAspectMultipler(buffer);

    var hsx = half_size.x * aspect_multiplier * scale;
    var hsy = half_size.y * aspect_multiplier * scale;
    var px = p.x * aspect_multiplier * scale;
    var py = p.y * aspect_multiplier * scale;

    px += @intToFloat(f32, buffer.width) * 0.5;
    py += @intToFloat(f32, buffer.height) * 0.5;

    var x0 = @floatToInt(u32, clamp(f32, 0, px - hsx, @intToFloat(f32, buffer.width)));
    var y0 = @floatToInt(u32, clamp(f32, 0, py - hsy, @intToFloat(f32, buffer.height)));
    var x1 = @floatToInt(u32, clamp(f32, 0, px + hsx, @intToFloat(f32, buffer.width)));
    var y1 = @floatToInt(u32, clamp(f32, 0, py + hsy, @intToFloat(f32, buffer.height)));

    drawRectInPixels(buffer, x0, y0, x1, y1, color);
}

pub fn pixels_to_world(buffer: GameRenderBuffer, pixels_coord: Vec2i) Vec2f {
    var aspect_multiplier: f32 = calculateAspectMultipler(buffer);

    var result: Vec2f = undefined;
    result.x = @intToFloat(f32, pixels_coord.x) - @intToFloat(f32, buffer.width) * 0.5;
    result.y = @intToFloat(f32, pixels_coord.y) - @intToFloat(f32, buffer.height) * 0.5;

    result.x /= aspect_multiplier;
    result.x /= scale;

    result.y /= aspect_multiplier;
    result.y /= scale;

    return result;
}

pub fn drawNumber(buffer: GameRenderBuffer, number: i32, pos: Vec2f, size: f32, color: u32) void {
    var curr_number: i32 = number;
    var digit: i32 = @mod(curr_number, 10);
    var first_digit: bool = true;

    var square_size: f32 = size / 5.0;
    var half_square_size: f32 = size / 10.0;

    var p: Vec2f = pos;
    while (curr_number > 0 or first_digit) {
        first_digit = false;

        switch (digit) {
            0 => {
                drawRect(buffer, Vec2f.init(p.x - square_size, p.y), Vec2f.init(half_square_size, 2.5 * square_size), color);
                drawRect(buffer, Vec2f.init(p.x + square_size, p.y), Vec2f.init(half_square_size, 2.5 * square_size), color);
                drawRect(buffer, Vec2f.init(p.x, p.y + square_size * 2.0), Vec2f.init(half_square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x, p.y - square_size * 2.0), Vec2f.init(half_square_size, half_square_size), color);
                p.x -= square_size * 4.0;
            },

            1 => {
                drawRect(buffer, Vec2f.init(p.x + square_size, p.y), Vec2f.init(half_square_size, 2.0 * square_size), color);
                p.x -= square_size * 2.0;
            },

            2 => {
                drawRect(buffer, Vec2f.init(p.x, p.y + square_size * 2.0), Vec2f.init(1.5 * square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x, p.y), Vec2f.init(1.5 * square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x, p.y - square_size * 2.0), Vec2f.init(1.5 * square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x + square_size, p.y + square_size), Vec2f.init(half_square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x - square_size, p.y - square_size), Vec2f.init(half_square_size, half_square_size), color);
                p.x -= square_size * 4.0;
            },

            3 => {
                drawRect(buffer, Vec2f.init(p.x - half_square_size, p.y + square_size * 2.0), Vec2f.init(square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x - half_square_size, p.y), Vec2f.init(square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x - half_square_size, p.y - square_size * 2.0), Vec2f.init(square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x + square_size, p.y), Vec2f.init(half_square_size, 2.5 * square_size), color);
                p.x -= square_size * 4.0;
            },

            4 => {
                drawRect(buffer, Vec2f.init(p.x + square_size, p.y), Vec2f.init(half_square_size, 2.5 * square_size), color);
                drawRect(buffer, Vec2f.init(p.x - square_size, p.y + square_size), Vec2f.init(half_square_size, 1.5 * square_size), color);
                drawRect(buffer, Vec2f.init(p.x, p.y), Vec2f.init(half_square_size, half_square_size), color);
                p.x -= square_size * 4.0;
            },

            5 => {
                drawRect(buffer, Vec2f.init(p.x, p.y + square_size * 2.0), Vec2f.init(1.5 * square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x, p.y), Vec2f.init(1.5 * square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x, p.y - square_size * 2.0), Vec2f.init(1.5 * square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x - square_size, p.y + square_size), Vec2f.init(half_square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x + square_size, p.y - square_size), Vec2f.init(half_square_size, half_square_size), color);
                p.x -= square_size * 4.0;
            },

            6 => {
                drawRect(buffer, Vec2f.init(p.x + half_square_size, p.y + square_size * 2.0), Vec2f.init(square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x + half_square_size, p.y), Vec2f.init(square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x + half_square_size, p.y - square_size * 2.0), Vec2f.init(square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x - square_size, p.y), Vec2f.init(half_square_size, 2.5 * square_size), color);
                drawRect(buffer, Vec2f.init(p.x + square_size, p.y - square_size), Vec2f.init(half_square_size, half_square_size), color);
                p.x -= square_size * 4.0;
            },

            7 => {
                drawRect(buffer, Vec2f.init(p.x + square_size, p.y), Vec2f.init(half_square_size, 2.5 * square_size), color);
                drawRect(buffer, Vec2f.init(p.x - half_square_size, p.y + square_size * 2.0), Vec2f.init(square_size, half_square_size), color);
                p.x -= square_size * 4.0;
            },

            8 => {
                drawRect(buffer, Vec2f.init(p.x - square_size, p.y), Vec2f.init(half_square_size, 2.5 * square_size), color);
                drawRect(buffer, Vec2f.init(p.x + square_size, p.y), Vec2f.init(half_square_size, 2.5 * square_size), color);
                drawRect(buffer, Vec2f.init(p.x, p.y + square_size * 2.0), Vec2f.init(half_square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x, p.y - square_size * 2.0), Vec2f.init(half_square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x, p.y), Vec2f.init(half_square_size, half_square_size), color);
                p.x -= square_size * 4.0;
            },

            9 => {
                drawRect(buffer, Vec2f.init(p.x - half_square_size, p.y + square_size * 2.0), Vec2f.init(square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x - half_square_size, p.y), Vec2f.init(square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x - half_square_size, p.y - square_size * 2.0), Vec2f.init(square_size, half_square_size), color);
                drawRect(buffer, Vec2f.init(p.x + square_size, p.y), Vec2f.init(half_square_size, 2.5 * square_size), color);
                drawRect(buffer, Vec2f.init(p.x - square_size, p.y + square_size), Vec2f.init(half_square_size, half_square_size), color);
                p.x -= square_size * 4.0;
            },

            else => {
                unreachable;
            },
        }

        curr_number = @divTrunc(curr_number, 10);
        digit = @mod(curr_number, 10);
    }
}

pub inline fn clamp(comptime T: type, lower_limit: T, value: T, upper_limit: T) T {
    if (value < lower_limit) {
        return lower_limit;
    }
    if (value > upper_limit) {
        return upper_limit;
    }
    return value;
}

pub fn drawRectInPixels(buffer: GameRenderBuffer, x0: u32, y0: u32, x1: u32, y1: u32, color: u32) void {
    var xc0 = clamp(u32, 0, x0, buffer.width);
    var xc1 = clamp(u32, 0, x1, buffer.width);
    var yc0 = clamp(u32, 0, y0, buffer.height);
    var yc1 = clamp(u32, 0, y1, buffer.height);

    var y = yc0;
    while (y < yc1) : (y += 1) {
        var x = xc0;
        while (x < xc1) : (x += 1) {
            buffer.memory[x + y * buffer.width] = color;
        }
    }
}

inline fn calculateAspectMultipler(buffer: GameRenderBuffer) f32 {
    var aspect_multiplier = @intToFloat(f32, buffer.height);
    if (@intToFloat(f32, buffer.width) / @intToFloat(f32, buffer.height) < 1.77) {
        aspect_multiplier = @intToFloat(f32, buffer.width) / 1.77;
    }

    return aspect_multiplier;
}

pub fn drawTransparentRect(buffer: GameRenderBuffer, p: Vec2f, half_size: Vec2f, color: u32, alpha: f32) void {
    var aspect_multiplier: f32 = calculateAspectMultipler(buffer);

    var scaled_half_size_x: f32 = half_size.x * aspect_multiplier * scale;
    var scaled_half_size_y: f32 = half_size.y * aspect_multiplier * scale;

    var scaled_p_x: f32 = p.x * aspect_multiplier * scale;
    var scaled_p_y: f32 = p.y * aspect_multiplier * scale;

    scaled_p_x += @intToFloat(f32, buffer.width) * 0.5;
    scaled_p_y += @intToFloat(f32, buffer.height) * 0.5;

    var x0: u32 = @floatToInt(u32, scaled_p_x - scaled_half_size_x);
    var y0: u32 = @floatToInt(u32, scaled_p_y - scaled_half_size_y);
    var x1: u32 = @floatToInt(u32, scaled_p_x + scaled_half_size_x);
    var y1: u32 = @floatToInt(u32, scaled_p_y + scaled_half_size_y);

    drawTransparentRectInPixels(buffer, x0, y0, x1, y1, color, alpha);
}

fn drawTransparentRectInPixels(buffer: GameRenderBuffer, x0: u32, y0: u32, x1: u32, y1: u32, color: u32, alpha: f32) void {
    var x0c = clamp(u32, 0, x0, buffer.width);
    var x1c = clamp(u32, 0, x1, buffer.width);
    var y0c = clamp(u32, 0, y0, buffer.height);
    var y1c = clamp(u32, 0, y1, buffer.height);

    var alphac = clamp(f32, 0, alpha, 1);

    var y = y0c;
    while (y < y1c) : (y += 1) {
        var x = x0c;
        while (x < x1c) : (x += 1) {
            const pixel_color: u32 = buffer.memory[x + y * buffer.width];
            buffer.memory[x + y * buffer.width] = lerpColor(pixel_color, alpha, color);
        }
    }
}

fn lerp(a: f32, t: f32, b: f32) f32 {
    var result = (1 - t) * a + t * b;
    return result;
}

fn lerpColor(a: u32, t: f32, b: u32) u32 {
    var a_r: f32 = @intToFloat(f32, ((a & 0xff0000) >> 16));
    var a_g: f32 = @intToFloat(f32, ((a & 0xff00) >> 8));
    var a_b: f32 = @intToFloat(f32, (a & 0xff));

    var b_r: f32 = @intToFloat(f32, ((b & 0xff0000) >> 16));
    var b_g: f32 = @intToFloat(f32, ((b & 0xff00) >> 8));
    var b_b: f32 = @intToFloat(f32, (b & 0xff));

    var red = @floatToInt(u8, @mod(lerp(a_r, t, b_r), 255.0));
    var green = @floatToInt(u8, @mod(lerp(a_g, t, b_g), 255.0));
    var blue = @floatToInt(u8, @mod(lerp(a_b, t, b_b), 255.0));

    var result = makeColor(red, green, blue);
    return result;
}

pub inline fn makeColor(r: u8, g: u8, b: u8) u32 {
    return (@intCast(u32, b) << 0) | (@intCast(u32, g) << 8) | (@intCast(u32, r) << 16);
}

const std = @import("std");
pub fn drawTransparentRotatedRect(buffer: GameRenderBuffer, p: Vec2f, half_size: Vec2f, angle: f32, color: u32, alpha: f32) void { //In degrees
    var alpha_c = clamp(f32, 0, alpha, 1);

    var angle_r = math.degToRad(angle);

    var cos = math.cosf(angle_r);
    var sin = math.sinf(angle_r);

    var x_axis: Vec2f = Vec2f.init(cos, sin).mul(half_size.x * 2);
    var y_axis: Vec2f = Vec2f.init(-sin, cos).mul(half_size.y * 2);

    drawRectSlow(buffer, p, x_axis, y_axis, color, alpha_c);
}

pub fn drawRectSlow(buffer: GameRenderBuffer, origin: Vec2f, xAxis: Vec2f, yAxis: Vec2f, color: u32, alpha: f32) void {
    const aspect_multiplier = calculateAspectMultipler(buffer);

    var pOrigin = origin.mul(aspect_multiplier * scale);
    var pxAxis = xAxis.mul(aspect_multiplier * scale);
    var pyAxis = yAxis.mul(aspect_multiplier * scale);

    var offset = Vec2f.init(@intToFloat(f32, buffer.width) * 0.5, @intToFloat(f32, buffer.height) * 0.5);

    pOrigin = pOrigin.add(offset);

    var width = @intCast(i32, buffer.width);
    var height = @intCast(i32, buffer.height);

    var xMin: i32 = width;
    var xMax: i32 = 0;
    var yMin: i32 = height;
    var yMax: i32 = 0;

    var points = [4]Vec2f{ pOrigin, pOrigin.add(pxAxis), pOrigin.add(pxAxis).add(pyAxis), pOrigin.add(pyAxis) };
    for (points) |p| {
        var fx = math.truncf32(p.x);
        var cx = math.ceil32(p.x);
        var fy = math.truncf32(p.y);
        var cy = math.ceil32(p.y);

        if (xMin > fx) xMin = fx;
        if (yMin > fy) yMin = fy;
        if (xMax < cx) xMax = cx;
        if (yMax < cy) yMax = cy;
    }

    if (xMin < 0) xMin = 0;
    if (yMin < 0) yMin = 0;
    if (xMax > width) xMax = width;
    if (yMax > height) yMax = height;

    var y = @intCast(u32, yMin);
    while (y < yMax) : (y += 1) {
        var x = @intCast(u32, xMin);
        while (x < xMax) : (x += 1) {
            var pixelP = Vec2f.init(@intToFloat(f32, x), @intToFloat(f32, y));

            var edge0 = pixelP.sub(pOrigin).dot(pxAxis.perp().neg());
            var edge1 = pixelP.sub(pOrigin.add(pxAxis)).dot(pyAxis.perp().neg());
            var edge2 = pixelP.sub(pOrigin.add(pxAxis).add(pyAxis)).dot(pxAxis.perp());
            var edge3 = pixelP.sub(pOrigin.add(pyAxis)).dot(pyAxis.perp());

            if (edge0 < 0 and edge1 < 0 and edge2 < 0 and edge3 < 0) {
                var c = lerpColor(buffer.memory[x + y * buffer.width], alpha, color);
                buffer.memory[x + y * buffer.width] = c;
            }
        }
    }
}
