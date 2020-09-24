pub const Piece = struct {
    name: u8,
    color: u32,
    layout: [4][4][4]bool,
};

const F = false;
const T = true;

pub const pieces = [_]Piece{
    Piece{
        .name = 'I',
        .color = 0x00ffff,
        .layout = [_][4][4]bool{
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, T, T },
                [_]bool{ F, F, F, F },
            },
            [_][4]bool{
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, T, T },
                [_]bool{ F, F, F, F },
            },
            [_][4]bool{
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
            },
        },
    },
    Piece{
        .name = 'O',
        .color = 0xffff00,
        .layout = [_][4][4]bool{
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ T, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ T, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ T, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ T, T, F, F },
            },
        },
    },
    Piece{
        .name = 'T',
        .color = 0xff00ff,
        .layout = [_][4][4]bool{
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, T, F },
                [_]bool{ F, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ T, T, T, F },
                [_]bool{ F, F, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, T, F },
                [_]bool{ F, T, F, F },
            },
        },
    },
    Piece{
        .name = 'J',
        .color = 0x0000ff,
        .layout = [_][4][4]bool{
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ T, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ T, F, F, F },
                [_]bool{ T, T, T, F },
                [_]bool{ F, F, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, T, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, T, F },
                [_]bool{ F, F, T, F },
            },
        },
    },
    Piece{
        .name = 'L',
        .color = 0xff8000,
        .layout = [_][4][4]bool{
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, T, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, T, F },
                [_]bool{ T, F, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, F, F },
                [_]bool{ F, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, T, F },
                [_]bool{ T, T, T, F },
                [_]bool{ F, F, F, F },
            },
        },
    },
    Piece{
        .name = 'S',
        .color = 0x00ff00,
        .layout = [_][4][4]bool{
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, T, F },
                [_]bool{ T, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ T, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ F, T, T, F },
                [_]bool{ T, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ T, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, F, F },
            },
        },
    },
    Piece{
        .name = 'Z',
        .color = 0xff0000,
        .layout = [_][4][4]bool{
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, T, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, T, F },
                [_]bool{ F, T, T, F },
                [_]bool{ F, T, F, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, F, F },
                [_]bool{ T, T, F, F },
                [_]bool{ F, T, T, F },
            },
            [_][4]bool{
                [_]bool{ F, F, F, F },
                [_]bool{ F, F, T, F },
                [_]bool{ F, T, T, F },
                [_]bool{ F, T, F, F },
            },
        },
    },
};
