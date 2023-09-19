const std = @import("std");

const buffer_size: i32 = 2048;
export var buffer: [buffer_size]u8 = undefined;

extern fn alertWithGlobalBufferAndSize(i32) void;

extern fn alert() void;

export fn main() void {
    const message = "Hello";
    std.mem.copy(u8, buffer[0..], message[0..]);
    alertWithGlobalBufferAndSize(message.len);
}
