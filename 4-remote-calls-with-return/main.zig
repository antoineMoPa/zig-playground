const std = @import("std");

// Must match definitions in native code
const TYPE_NULL = 0;
const TYPE_FLOAT = 1;

// JS communication output data.
// (Zig to JS commmunication buffer where we send expressions)
const buffer_size: i32 = 2048;
export var buffer: [buffer_size]u8 = undefined;

// Define string type for convenience
const str: type = []const u8;

// Start an expression ( the "(" in (console.log 42))
extern fn openExpression() void;
// Close an expression ( the ")" in (console.log 42))
// closing an expression results in its evaluation in JS, with a valueType
// returned, and data in our result registers.
extern fn closeExpression() i32;
extern fn receiveStringToken(i32) void;
extern fn receiveNumberToken(f32) void;
extern fn getLastExpressionFloatResult() f32;

const JSResult = struct {
    floatValue: f32,
    valueType: i32,

    pub fn asInt(self: JSResult) i32 {
        return @intFromFloat(self.floatValue);
    }
};

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

fn closeExpressionAndGetResult() JSResult {
    var result = JSResult{
        .floatValue = 0,
        .valueType = 0,
    };

    const valueType = closeExpression();
    result.valueType = valueType;
    result.floatValue = getLastExpressionFloatResult();

    return result;
}

fn sendTokenString(message: []const u8) void {
    sendToken([]const u8, message);
}

fn getResultInt() i32 {
    return 0;
}

fn debug(comptime T: type, message: T) void {
    openExpression();
    sendToken(str, "console.log");
    sendToken(T, message);
    _ = closeExpression();
}

export fn main() void {
    openExpression();
    sendToken(str, "+");
    sendToken(i32, 40);
    openExpression();
    sendToken(str, "+");
    sendToken(i32, 1);
    sendToken(i32, 1);
    const result1 = closeExpressionAndGetResult();
    const result2 = closeExpressionAndGetResult();

    debug(str, "Result 1");
    debug(i32, result1.asInt());
    debug(str, "Result 2");
    debug(i32, result2.asInt());
}
