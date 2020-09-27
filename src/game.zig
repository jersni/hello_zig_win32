const render = @import("./render.zig");
const std = @import("std");
const math = @import("./math.zig");
const common = @import("./platform_common.zig");
const GameRenderBuffer = common.GameRenderBuffer;
const GameInput = common.GameInput;
const Vec2f = math.Vec2f;
const Vec2i = math.Vec2i;

const Piece = @import("pieces.zig").Piece;

const BACKGROUND = render.makeColor(0x0, 0x0, 0x0);
const pieces = @import("pieces.zig").pieces;
var piece: Piece = undefined;
var piece_rot: usize = 0;
var piece_row: usize = board_rows;
var piece_col: usize = 4;
var new_piece: bool = true;
var game_over: bool = false;
var score: i32 = 0;
const score_p: Vec2f = Vec2f.init(board_left + @intToFloat(f32, board_cols) * block_half_width.x * 2 + 20, 20);

var drop_interval: f32 = 0.25;
var drop_t: f32 = 0.25;
var control_delay: f32 = 0;
pub fn simulate(buffer: GameRenderBuffer, input: *GameInput) void {
    control_delay += input.dt_for_frame;
    drop_t -= input.dt_for_frame;

    render.clearScreen(buffer, BACKGROUND);

    render.drawNumber(buffer, score, score_p, 5.0, 0xffffff);
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
                    var color = board[r][c].Occupied;
                    board[r][c] = Cell{ .Empty = 0x0 };
                    spawnParticleExplosion(30, get_board_pos(r, c), 8.0, 1.0, 0.15, color);
                }
            }
        }
        if (drop_all) {
            // there were some full rows, so drop all the pieces
            var lines: usize = highest_emptied_row - lowest_emptied_row + 1;
            while (lowest_emptied_row + lines < board_rows - 1) : (lowest_emptied_row += 1) {
                var col: usize = 0;
                while (col < board_cols) : (col += 1) {
                    board[lowest_emptied_row][col] = board[lowest_emptied_row + lines][col];
                }
            }
            score += get_score(lines);
        }
    }

    // render board and pieces
    for (board) |row, row_index| {
        for (row) |cell, column_index| {
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
            render.drawRect(buffer, get_board_pos(row_index, column_index), block_size, cell_color);
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

fn get_score(lines: usize) i32 {
    var result: i32 = 0;
    if (lines == 1) {
        result = 40;
    } else if (lines == 2) {
        result = 100;
    } else if (lines == 3) {
        result = 30;
    } else if (lines == 4) {
        result = 1200;
    }
    return result;
}

fn get_board_pos(row: usize, column: usize) Vec2f {
    return Vec2f.init(board_left + @intToFloat(f32, 2 * column) * block_half_width.x, @intToFloat(f32, (2 * row)) * block_half_width.x + board_bottom);
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
    return math.random_in_range(usize, 0, pieces.len - 1);
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
// * falling, speed up as time goes on
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
    particle.dp = Vec2f.init(math.random_bilateral() * dp_scale, math.random_bilateral() * dp_scale);
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
        bs += math.random_bilateral() * 0.1 * bs;
        bl += math.random_bilateral() * 0.1 * bl;
        var particle = spawnParticle(p, dp_scale, Vec2f.init(bs, bs), bl, 1.0, color);
    }
}
