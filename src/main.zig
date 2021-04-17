const std = @import("std");
const game = @import("./game.zig");
const common = @import("./platform_common.zig");

usingnamespace std.os.windows;

const DIB_RGB_COLORS = 0;
const SRCCOPY = 0x00CC0020;

const BI_RGB = 0x0000;

const WS_VISIBLE = @as(c_long, 0x10000000);
const WS_OVERLAPPED = @as(c_long, 0x00000000);
const WS_CAPTION = @as(c_long, 0x00C00000);
const WS_SYSMENU = @as(c_long, 0x00080000);
const WS_THICKFRAME = @as(c_long, 0x00040000);
const WS_MINIMIZEBOX = @as(c_long, 0x00020000);
const WS_MAXIMIZEBOX = @as(c_long, 0x00010000);
const WS_OVERLAPPEDWINDOW = (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX);

const WM_SYSKEYDOWN = 260;
const WM_SYSKEYUP = 261;
const WM_KEYDOWN = 256;
const WM_KEYUP = 257;

const VK_LEFT = 37;
const VK_UP = 38;
const VK_RIGHT = 39;
const VK_DOWN = 40;
const VK_LBUTTON = 1;
const VK_MBUTTON = 4;
const VK_RBUTTON = 2;
const VK_XBUTTON1 = 5;
const VK_XBUTTON2 = 6;

const VREFRESH = 116;

const TIMERR_NOERROR = 0;

const RGBQUAD = extern struct {
    rgbBlue: BYTE,
    rgbGreen: BYTE,
    rgbRed: BYTE,
    rgbReserved: BYTE,
};

const BITMAPINFOHEADER = extern struct {
    biSize: DWORD = @sizeOf(BITMAPINFOHEADER),
    biWidth: LONG = 1280,
    biHeight: LONG = 720,
    biPlanes: WORD = 1,
    biBitCount: WORD = 32,
    biCompression: DWORD = BI_RGB,
    biSizeImage: DWORD = 0,
    biXPelsPerMeter: LONG = 0,
    biYPelsPerMeter: LONG = 0,
    biClrUsed: DWORD = 0,
    biClrImportant: DWORD = 0,
};

const BITMAPINFO = extern struct {
    bmiHeader: BITMAPINFOHEADER,
    bmiColors: [1]RGBQUAD,
};

pub const LPPOINT = [*c]POINT;

extern "kernel32" fn GetModuleHandleA(lpModuleName: ?LPCTSTR) callconv(WINAPI) HINSTANCE;
extern "user32" fn GetClientRect(hwnd: HWND, lpRect: *RECT) callconv(WINAPI) BOOL;
extern "user32" fn GetCursorPos(lpPoint: LPPOINT) callconv(WINAPI) BOOL;
extern "user32" fn ScreenToClient(hWnd: HWND, lpPoint: LPPOINT) callconv(WINAPI) BOOL;
extern "user32" fn GetKeyState(nVirtKey: c_int) callconv(WINAPI) SHORT;
extern "gdi32" fn StretchDIBits(hdc: HDC, xDest: c_int, yDest: c_int, DestWidth: c_int, DestHeight: c_int, xSrc: c_int, ySrc: c_int, SrcWidth: c_int, SrcHeight: c_int, lpBits: ?*const c_void, lpbmi: [*c]const BITMAPINFO, iUsage: UINT, rop: DWORD) callconv(WINAPI) c_int;
extern "gdi32" fn GetDeviceCaps(hdc: HDC, index: c_int) callconv(WINAPI) c_int;
extern "winmm" fn timeBeginPeriod(uPeriod: c_uint) callconv(WINAPI) c_uint;
extern "kernel32" fn Sleep(dwMilliseconds: DWORD) callconv(WINAPI) void;

const RenderBuffer = struct {
    width: LONG,
    height: LONG,
    pixels: ?[]u32,
    bitmap_info: BITMAPINFO,
};

var global_render_buffer = RenderBuffer{
    .width = 0,
    .height = 0,
    .pixels = null,
    .bitmap_info = BITMAPINFO{
        .bmiHeader = undefined,
        .bmiColors = [_]RGBQUAD{RGBQUAD{ .rgbBlue = 0, .rgbGreen = 0, .rgbRed = 0, .rgbReserved = 0 }},
    },
};
var running = true;
var global_perf_count_frequency: u64 = 0;

fn wndProc(window: HWND, message: c_uint, w_param: usize, l_param: LRESULT) callconv(WINAPI) LRESULT {
    var result: LRESULT = 0;
    switch (message) {
        user32.WM_DESTROY, user32.WM_CLOSE => {
            running = false;
        },
        user32.WM_SIZE => {
            var rect: RECT = undefined;
            if (GetClientRect(window, &rect) == 0) {
                std.debug.warn("GetClientRect failed ...\n", .{});
                unreachable;
            }
            global_render_buffer.width = rect.right - rect.left;
            global_render_buffer.height = rect.bottom - rect.top;

            if (global_render_buffer.pixels) |value| {
                if (kernel32.VirtualFree(value.ptr, 0, MEM_RELEASE) == 0) {
                    std.debug.warn("VirtualFree failed ... {}\n", .{kernel32.GetLastError()});
                }
                global_render_buffer.pixels = null;
            }
            var sz = @sizeOf(u32) * @intCast(usize, global_render_buffer.width * global_render_buffer.height);
            if (sz > 0) {
                if (VirtualAlloc(null, sz, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE)) |value| {
                    global_render_buffer.pixels = @ptrCast([*]u32, @alignCast(4, value))[0..(sz / @sizeOf(u32))];
                } else |err| {
                    std.debug.warn("uh oh ... {}\n", .{err});
                    unreachable;
                }
            }

            var bmi = BITMAPINFOHEADER{
                .biWidth = global_render_buffer.width,
                .biHeight = global_render_buffer.height,
            };
            global_render_buffer.bitmap_info.bmiHeader = bmi;
        },
        else => {
            return user32.DefWindowProcA(window, message, w_param, l_param);
        },
    }
    return result;
}

pub fn main() void {
    var hInstance = GetModuleHandleA(null);
    var className: LPCSTR = "test";
    global_perf_count_frequency = QueryPerformanceFrequency();

    const desired_scheduler_ms: UINT = 1;
    var sleep_is_granular: bool = (timeBeginPeriod(desired_scheduler_ms) == TIMERR_NOERROR);

    var window_class = user32.WNDCLASSEXA{
        .style = user32.CS_HREDRAW | user32.CS_VREDRAW,
        .lpfnWndProc = wndProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = hInstance,
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = className,
        .hIconSm = null,
    };

    if (user32.RegisterClassExA(&window_class) != 0) {
        if (user32.CreateWindowExA(0, className, "Hello, world!", WS_VISIBLE | WS_OVERLAPPEDWINDOW, 0, 0, 1280, 720, null, null, hInstance, null)) |window| {
            if (user32.GetDC(window)) |hdc| {
                var monitor_refresh_hz: i32 = 60;
                const win32_refresh_rate: i32 = GetDeviceCaps(hdc, VREFRESH);
                if (win32_refresh_rate > 1) {
                    monitor_refresh_hz = win32_refresh_rate;
                }
                const game_update_hz: f32 = (@intToFloat(f32, monitor_refresh_hz) / 2.0);
                const target_seconds_per_frame: f32 = 1.0 / game_update_hz;
                var last_counter = QueryPerformanceCounter();

                var input: [2]common.GameInput = undefined;
                input[0] = common.GameInput{};
                input[1] = common.GameInput{};
                var new_input: *common.GameInput = &input[0];
                var old_input: *common.GameInput = &input[1];

                while (running) {
                    new_input.dt_for_frame = target_seconds_per_frame;
                    var old_keyboard_controller = &old_input.controllers[0];
                    var new_keyboard_controller = &new_input.controllers[0];
                    new_keyboard_controller.zero();
                    new_keyboard_controller.is_connected = true;

                    // NOTE: buttons function instead of having a union in the controller of individual button state and an array of button state.
                    const old_keyboard_buttons = old_keyboard_controller.pad.buttons;
                    for (new_keyboard_controller.pad.buttons) |*b, i| {
                        b.ended_down = old_keyboard_buttons[i].ended_down;
                    }

                    processPendingMessages(new_keyboard_controller);

                    {
                        var mouse_pointer: POINT = undefined;
                        _ = GetCursorPos(&mouse_pointer);
                        _ = ScreenToClient(window, &mouse_pointer);
                        new_input.mouse_x = mouse_pointer.x;
                        new_input.mouse_y = global_render_buffer.height - mouse_pointer.y;
                        new_input.mouse_z = 0; // TODO: support mouse wheel?
                        processKeyboardMessage(&new_input.mouse_buttons[0], (@as(i32, GetKeyState(VK_LBUTTON)) & (1 << 15)) != 0);
                        processKeyboardMessage(&new_input.mouse_buttons[1], (@as(i32, GetKeyState(VK_MBUTTON)) & (1 << 15)) != 0);
                        processKeyboardMessage(&new_input.mouse_buttons[2], (@as(i32, GetKeyState(VK_RBUTTON)) & (1 << 15)) != 0);
                        processKeyboardMessage(&new_input.mouse_buttons[3], (@as(i32, GetKeyState(VK_XBUTTON1)) & (1 << 15)) != 0);
                        processKeyboardMessage(&new_input.mouse_buttons[4], (@as(i32, GetKeyState(VK_XBUTTON2)) & (1 << 15)) != 0);
                    }

                    if (global_render_buffer.pixels) |pixels| {
                        // the simulation begins here
                        game.simulate(common.GameRenderBuffer{
                            .width = @intCast(u32, global_render_buffer.width),
                            .height = @intCast(u32, global_render_buffer.height),
                            .memory = pixels,
                        }, new_input);

                        //Get the frame time
                        var work_seconds_elapsed = getSecondsElapsed(last_counter, QueryPerformanceCounter());

                        var seconds_elapsed_for_frame = work_seconds_elapsed;
                        if (seconds_elapsed_for_frame < target_seconds_per_frame) {
                            if (sleep_is_granular) {
                                var sleep_ms: DWORD = @floatToInt(DWORD, (1000.0 * (target_seconds_per_frame - seconds_elapsed_for_frame)));
                                if (sleep_ms > 0) {
                                    Sleep(sleep_ms);
                                }
                            }

                            var test_seconds_elapsed_for_frame: f32 = getSecondsElapsed(last_counter, QueryPerformanceCounter());
                            if (test_seconds_elapsed_for_frame < target_seconds_per_frame) {
                                //std.debug.warn("Missed sleep here ...\n", .{});
                            }

                            while (seconds_elapsed_for_frame < target_seconds_per_frame) {
                                seconds_elapsed_for_frame = getSecondsElapsed(last_counter, QueryPerformanceCounter());
                            }
                        } else {
                            // TODO: happening when the window is resized / moved
                            std.debug.warn("Missed frame rate ...\n", .{});
                        }

                        //Render
                        _ = StretchDIBits(hdc, 0, 0, global_render_buffer.width, global_render_buffer.height, 0, 0, global_render_buffer.width, global_render_buffer.height, pixels.ptr, &global_render_buffer.bitmap_info, DIB_RGB_COLORS, SRCCOPY);

                        const end_counter = QueryPerformanceCounter();
                        const ms_per_frame: f32 = 1000.0 * getSecondsElapsed(last_counter, end_counter);
                        last_counter = end_counter;
                        // std.debug.warn("ms/f {d}\n", .{ms_per_frame});

                        var temp: *common.GameInput = new_input;
                        new_input = old_input;
                        old_input = temp;
                    }
                }
            } else {
                std.debug.panic("GetDC failed!\n", .{});
            }
        } else {
            std.debug.panic("CreateWindowExA failed!\n", .{});
        }
    } else {
        std.debug.panic("RegisterClassExA failed!\n", .{});
    }
}

fn processPendingMessages(keyboard_controller: *common.GameControllerInput) void {
    var message: user32.MSG = undefined;
    while (user32.PeekMessageA(&message, null, 0, 0, user32.PM_REMOVE) != 0) {
        switch (message.message) {
            user32.WM_QUIT => {
                running = false;
            },
            WM_KEYDOWN, WM_KEYUP, WM_SYSKEYDOWN, WM_SYSKEYUP => {
                var vk_code: usize = message.wParam;

                const previous_state_flag: u64 = 1 << 30;
                const transition_flag: u64 = 1 << 31;
                var was_down = (message.lParam & previous_state_flag) != 0;
                var is_down = (message.lParam & transition_flag) == 0;

                if (was_down != is_down) {
                    switch (vk_code) {
                        VK_LEFT => {
                            processKeyboardMessage(&keyboard_controller.pad.button.move_left, is_down);
                        },
                        VK_RIGHT => {
                            processKeyboardMessage(&keyboard_controller.pad.button.move_right, is_down);
                        },
                        VK_UP => {
                            processKeyboardMessage(&keyboard_controller.pad.button.move_up, is_down);
                        },
                        VK_DOWN => {
                            processKeyboardMessage(&keyboard_controller.pad.button.move_down, is_down);
                        },
                        else => {},
                    }
                }
            },
            else => {
                _ = user32.TranslateMessage(&message);
                _ = user32.DispatchMessageA(&message);
            },
        }
    }
}

fn getSecondsElapsed(start: u64, end: u64) f32 {
    const result: f32 = @intToFloat(f32, (end - start)) / @intToFloat(f32, global_perf_count_frequency);
    return result;
}

fn processKeyboardMessage(new_state: *common.GameButtonState, is_down: bool) void {
    if (new_state.ended_down != is_down) {
        new_state.ended_down = is_down;
        new_state.half_transition_count += 1;
    }
}
