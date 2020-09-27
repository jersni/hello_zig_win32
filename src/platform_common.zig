pub const GameRenderBuffer = struct {
    width: u32,
    height: u32,
    memory: []u32,
};

pub const GameButtonState = packed struct {
    half_transition_count: i32 = 0,
    ended_down: bool = false,
    _: u31 = 0,
};

pub const GameControllerInput = struct {
    const Self = @This();

    is_connected: bool = false,
    is_analog: bool = false,
    stick_average_x: f32 = 0,
    stick_average_y: f32 = 0,
    pad: packed union {
        buttons: [4]GameButtonState,
        button: packed struct {
            move_up: GameButtonState,
            move_down: GameButtonState,
            move_left: GameButtonState,
            move_right: GameButtonState,
        },
    } = .{ .buttons = [_]GameButtonState{GameButtonState{}} ** 4 },

    pub fn zero(self: *Self) void {
        self.is_connected = false;
        self.is_analog = false;
        self.stick_average_x = 0;
        self.stick_average_y = 0;
        for (self.pad.buttons) |*b| {
            b.ended_down = false;
            b.half_transition_count = 0;
        }
    }
};

pub const GameInput = struct {
    const num_mouse_buttons = 5;
    const num_controllers = 1;

    mouse_buttons: [num_mouse_buttons]GameButtonState = [_]GameButtonState{GameButtonState{}} ** num_mouse_buttons,
    mouse_x: i32 = 0,
    mouse_y: i32 = 0,
    mouse_z: i32 = 0,

    dt_for_frame: f32 = 0,

    controllers: [num_controllers]GameControllerInput = [_]GameControllerInput{GameControllerInput{}} ** num_controllers,
};
