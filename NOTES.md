

# WinMain

Not using `pub export fn WinMain(hInstance: HINSTANCE, hPrevInstace: HINSTANCE, lpCmdLine: PWSTR, nCmdShow: c_int) callconv(.Stdcall) c_int` due to:

https://github.com/ziglang/zig/issues/5002
https://github.com/ziglang/zig/pull/5613

# zig win32 bindings

helpful stuff for calling win32 from zig

* https://github.com/GoNZooo/zig-win32 - need to learn how to use other people's code / libs with my own
* the zig source under zig\lib\zig\std\os

# MS / Win32 docs

typedef  enum
{
  BI_RGB = 0x0000,
  BI_RLE8 = 0x0001,
  BI_RLE4 = 0x0002,
  BI_BITFIELDS = 0x0003,
  BI_JPEG = 0x0004,
  BI_PNG = 0x0005,
  BI_CMYK = 0x000B,
  BI_CMYKRLE8 = 0x000C,
  BI_CMYKRLE4 = 0x000D
} Compression;


https://docs.microsoft.com/en-us/windows/win32/gdi/ternary-raster-operations - SRCCOPY value found there

https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-emf/a5e722e3-891a-4a67-be1a-ed5a48a7fda1 - DIB_RGB_COLORS found there


## MSG lParam

It's different depending on the event. E.g. Bit 31 is 0 for WM_SYSKEYDOWN and WM_KEYDOWN. It's 1 for WM_SYSKEYUP and WM_KEYUP 
Bit 30 - 	The previous key state. The value is 1 if the key is down before the message is sent, or it is zero if the key is up.

https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-keydown 
https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-syskeydown 
https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-keyup
https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-syskeyup


# Game references

Handmade hero - this is my main reference - https://handmadehero.org/watch

Dan Zaiden has this series. Left off on part 6 @ 1hr. Similar to handmade hero, but shorter - making breakout.

https://www.youtube.com/watch?v=MyukZub9wQs&list=PL7Ej6SUky1357r-Lqf_nogZWHssXP-hvH&index=7


https://github.com/andrewrk/tetris - copied the Piece structure and pieces array from here; nicer and easier to use than what I started with ...