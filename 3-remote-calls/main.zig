const std = @import("std");

const buffer_size: i32 = 2048;
export var buffer: [buffer_size]u8 = undefined;

extern fn receiveStringToken(i32) void;
extern fn receiveNumberToken(f32) void;

fn sendToken(comptime T: type, message: T) void {
    if (T == []const u8) {
        std.mem.copy(u8, buffer[0..], message[0..]);
        receiveStringToken(@intCast(message.len));
    } else if (T == i32) {
        receiveNumberToken(@floatFromInt(message));
    } else if (T == f32) {
        receiveNumberToken(message);
    }
}

fn sendTokenString(message: []const u8) void {
    sendToken([]const u8, message);
}

export fn main() void {
    const str: type = []const u8;

    // sendToken(str, "(");
    // sendToken(str, "console.log");
    // sendToken(str, "(");
    // sendToken(str, "+");
    // sendToken(i32, 42);
    // sendToken(str, "(");
    // sendToken(str, "+");
    // sendToken(i32, 4);
    // sendToken(i32, 5);
    // sendToken(i32, 1);
    // sendToken(str, ")");
    // sendToken(str, ")");
    // sendToken(str, ")");

    sendToken(str, "(");
    sendToken(str, "console.log");
    sendToken(str, "(");
    sendToken(str, "+");
    sendToken(i32, 40);
    sendToken(i32, 2);
    sendToken(str, ")");
    sendToken(str, ")");
}
