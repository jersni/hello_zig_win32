const common = @import("./platform_common.zig");
const Vec2f = @import("./platform_common.zig").Vec2f;
const Vec2i = @import("./platform_common.zig").Vec2i;
const render = @import("./render.zig");
const std = @import("std");
const math = std.math;

const Piece = @import("pieces.zig").Piece;

const BACKGROUND = render.makeColor(0x0, 0x0, 0x0);
const pieces = @import("pieces.zig").pieces;
var piece: Piece = undefined;
var piece_rot: usize = 0;
var piece_row: usize = board_rows;
var piece_col: usize = 4;
var new_piece: bool = true;
var game_over: bool = false;

var drop_interval: f32 = 0.25;
var drop_t: f32 = 0.25;
var control_delay: f32 = 0;
pub fn simulate(buffer: common.GameRenderBuffer, input: *common.GameInput) void {
    control_delay += input.dt_for_frame;
    drop_t -= input.dt_for_frame;

    render.clearScreen(buffer, BACKGROUND);
    // TODO: only need fill in the borders once
    for (board) |row, row_index| {
        for (row) |_, column_index| {
            if (row_index == 0 or column_index == 0 or column_index == board_cols - 1) board[row_index][column_index] = Cell{ .Occupied = 0xfefefe };
        }
    }

    var controller = input.controllers[0];

    if (new_piece) {
        piece = pieces[randomPiece()];
        piece_rot = 0;
        piece_row = board_rows;
        piece_col = 4;
        new_piece = false;
        if (!can_move(piece, piece_row - 1, piece_col, piece_rot)) {
            game_over = true;
        }
    }
    var old_piece_row = piece_row;
    var old_piece_col = piece_col;
    var old_piece_rot = piece_rot;
    if (!game_over) {
        if (control_delay > 0.125) {
            if (controller.pad.button.move_left.ended_down) {
                if (piece_col > 0 and can_move(piece, piece_row, piece_col - 1, piece_rot)) {
                    piece_col -= 1;
                }
            } else if (controller.pad.button.move_right.ended_down) {
                if (can_move(piece, piece_row, piece_col + 1, piece_rot)) {
                    piece_col += 1;
                }
            } else if (controller.pad.button.move_up.ended_down) {
                if (can_move(piece, piece_row, piece_col, (piece_rot + 1) % 4)) {
                    piece_rot = (piece_rot + 1) % 4;
                }
            }
            if (controller.pad.button.move_down.ended_down) {
                drop_interval /= 5.0;
            } else if (!controller.pad.button.move_down.ended_down) {
                drop_interval = 0.25;
            }

            control_delay = 0;
        }

        if (drop_t <= 0) {
            if (piece_row > 0 and can_move(piece, piece_row - 1, piece_col, piece_rot)) {
                piece_row -= 1;
            } else {
                new_piece = true;
            }
            drop_t = drop_interval;
        }
    }

    // empty the old location on the board
    for (piece.layout[old_piece_rot]) |row, x| {
        for (row) |is_full, y| {
            if (!is_full) {
                continue;
            }
            board[old_piece_row - x][old_piece_col + y] = Cell{ .Empty = 0x000000 };
        }
    }

    // fill in the color in the new location
    for (piece.layout[piece_rot]) |row, x| {
        for (row) |is_full, y| {
            if (!is_full) {
                continue;
            } else {
                if (new_piece) {
                    // next frame will drop a new piece, lock the current piece in place
                    board[piece_row - x][piece_col + y] = Cell{ .Occupied = piece.color };
                } else {
                    // the current piece can still be moved; the cell on the board is still empty because the piece has not settled
                    board[piece_row - x][piece_col + y] = Cell{ .Empty = piece.color };
                }
            }
        }
    }

    if (new_piece) {
        // the current piece has settled. check for lines and empty the board locations if the row is full
        var r: usize = piece_row;
        var drop_all: bool = false;
        var lowest_emptied_row: usize = 0;
        var highest_emptied_row: usize = 0;
        while (r > 0) : (r -= 1) {
            var full: bool = true;
            for (board[r]) |cell| {
                if (cell == .Empty) {
                    full = false;
                }
            }
            if (full) {
                drop_all = true;
                if (highest_emptied_row == 0) {
                    highest_emptied_row = r;
                    lowest_emptied_row = r;
                } else {
                    lowest_emptied_row = r;
                }
                for (board[r]) |cell, c| {
                    var color = board[r][c];
                    board[r][c] = Cell{ .Empty = 0x0 };

                    // TODO: almost working - explosion is on the left only
                    const pos = Vec2f.init(board_left + @intToFloat(f32, c) * block_half_width.x, @intToFloat(f32, (2 * r)) * block_half_width.x + board_bottom);
                    spawnParticleExplosion(20, pos, block_half_width.x / 2.0, 1.5, 0.15, color.Occupied);
                }
            }
        }
        if (drop_all) {
            // there were some full rows, so drop all the pieces
            // TODO: this doesn't quite work yet. make two lines and only move down one. needs to keep falling
            var lines: usize = highest_emptied_row - lowest_emptied_row + 1;
            while (lowest_emptied_row < board_rows - 1) : (lowest_emptied_row += 1) {
                var col: usize = 0;
                while (col < board_cols) : (col += 1) {
                    if (lowest_emptied_row + lines < board_rows - 1) {
                        // TODO:fix this; maybe just add 4 more rows to the board so we don't go out of bounds
                        // or handle this in the outer loop? I don't think we miss anything
                        board[lowest_emptied_row][col] = board[lowest_emptied_row + lines][col];
                    }
                }
            }
        }
    }

    // render board and pieces
    for (board) |row, row_index| {
        for (row) |cell, column_index| {
            const pos = Vec2f.init(board_left + @intToFloat(f32, 2 * column_index) * block_half_width.x, @intToFloat(f32, (2 * row_index)) * block_half_width.x + board_bottom);
            var block_size: Vec2f = undefined;
            if (row_index == 0 or column_index == 0 or column_index == board_cols - 1) {
                block_size = block_half_width;
            } else {
                block_size = block_half_draw;
            }
            var cell_color = switch (cell) {
                .Empty => |color| color,
                .Occupied => |color| color,
            };
            render.drawRect(buffer, pos, block_size, cell_color);
        }
    }

    // render particles

    for (particles) |*p| {
        if (p.life <= 0) continue;
        p.life -= p.life_d * input.dt_for_frame;
        p.p = p.p.add(p.dp.mul(input.dt_for_frame));

        render.drawTransparentRect(buffer, p.p, p.half_size, p.color, p.life);
    }
}

var particle_y: f32 = -30;

fn can_move(the_piece: Piece, start_row: usize, start_col: usize, rotation: usize) bool {
    for (the_piece.layout[rotation]) |row, x| {
        for (row) |is_full, y| {
            if (is_full) {
                var target_x = start_row - x;
                var target_y = start_col + y;
                if (target_y == 0 or target_y == board_cols - 1) return false;
                if (target_x == 0) return false;
                var cell = board[target_x][target_y];
                var brd = board;
                if (cell == .Occupied) return false;
            }
        }
    }
    return true;
}

fn randomPiece() usize {
    var buf: [8]u8 = undefined;
    std.crypto.randomBytes(buf[0..]) catch |err| {
        std.debug.warn("error {}\n", .{err});
    };

    const seed = std.mem.readIntLittle(u64, buf[0..8]);
    var r = std.rand.DefaultPrng.init(seed);
    const s = r.random.int(usize);
    return std.rand.limitRangeBiased(usize, s, 6);
}

const board_half_draw = Vec2f.init(block_half_width.x * 0.95, block_half_width.y * 0.95);
const board_left: f32 = -20;
const board_bottom: f32 = -45;
const board_rows: usize = 23; // 22, with row 0 being the bottom border
const board_cols: usize = 12; // 10, with the column 0 and column 12 being the left / right border

var board: [board_rows][board_cols]Cell = [_][board_cols]Cell{[_]Cell{Cell{ .Empty = 0x0 }} ** board_cols} ** board_rows;

const Cell = union(enum) {
    Empty: u32,
    Occupied: u32,
};

const block_half_width = Vec2f.init(2, 2);
const block_half_draw = Vec2f.init(block_half_width.x * 0.85, block_half_width.y * 0.85);

const units_per_dt = block_half_width.x * 2;

// TODO:
// * look in to rotation; overrotates
// * falling, speed up as time goes on
// * scoring
// * https://www.playemulator.com/nes-online/classic-tetris/

const Particle = struct {
    p: Vec2f,
    dp: Vec2f,
    half_size: Vec2f,
    life: f32,
    life_d: f32,
    color: u32,
};

const empty_particle: Particle = Particle{
    .p = Vec2f.init(0, 0),
    .dp = Vec2f.init(0, 0),
    .half_size = Vec2f.init(1.0, 1.0),
    .life = 0,
    .life_d = 0,
    .color = 0x0,
};

var particles: [1024]Particle = [_]Particle{empty_particle} ** 1024;
var next_particle: usize = 0;

fn spawnParticle(p: Vec2f, dp_scale: f32, half_size: Vec2f, life: f32, life_d: f32, color: u32) *Particle {
    var np = next_particle;
    var particle = &particles[next_particle];
    next_particle += 1;
    if (next_particle >= particles.len) next_particle = 0;

    particle.p = p;
    particle.dp = Vec2f.init(random_bilateral() * dp_scale, random_bilateral() * dp_scale);
    particle.half_size = half_size;
    particle.life = life;
    particle.life_d = life_d;
    particle.color = color;

    return particle;
}

fn spawnParticleExplosion(count: i32, p: Vec2f, dp_scale: f32, base_size: f32, base_life: f32, color: u32) void {
    var i: i32 = 0;
    var bs: f32 = base_size;
    var bl: f32 = base_life;
    while (i < count) : (i += 1) {
        bs += random_bilateral() * 0.1 * bs;
        bl += random_bilateral() * 0.1 * bs;
        var particle = spawnParticle(p, dp_scale, Vec2f.init(bs, bs), bl, 1.0, color);
    }
}

var random_state: u32 = 1234; // TODO: Change the seed to be unique per game-run
fn random_u32() u32 {
    var result: u32 = random_state;
    result ^= result << 13;
    result ^= result >> 17;
    result ^= result << 5;
    random_state = result;
    return result;
}

const MAX_U32: f32 = 4294967295.0; // TODO: there must be a built in for this?
fn random_unilateral() f32 {
    return @intToFloat(f32, random_u32()) / MAX_U32;
}

fn random_bilateral() f32 {
    return random_unilateral() * 2.0 - 1.0;
}
