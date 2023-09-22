const std = @import("std");

// Must match definitions in js code
const TYPE_NULL = 0;
const TYPE_INT_8 = 1;
const TYPE_STR = 2;

// JS communication output data.
// (Zig to JS commmunication buffer where we send expressions)
const buffer_size: i32 = 2048;
export var u8Buffer: [buffer_size]u8 = undefined;

// Define string type for convenience
const str: type = []const u8;

// Start an expression ( the "(" in (console.log 42))
extern fn openExpression() void;
// Close an expression ( the ")" in (console.log 42))
// closing an expression results in its evaluation in JS, with a valueType
// returned, and data in our result registers.
extern fn closeExpression() void;
extern fn receiveStringToken(u8) void;
extern fn receiveNumberToken(f32) void;
extern fn getLastExpressionFloatResult() f32;
extern fn alertu8(u8) void;

const JSResult = struct {
    value: u8,
    str: [buffer_size]u8,
    valueType: u8,

    pub fn asInt(self: JSResult) u8 {
        return self.value;
    }
};

fn sendToken(comptime T: type, message: T) void {
    if (T == []const u8) {
        std.mem.copy(u8, u8Buffer[0..], message[0..]);
        receiveStringToken(@intCast(message.len));
    } else if (T == u8) {
        receiveNumberToken(@floatFromInt(message));
    } else if (T == usize) {
        receiveNumberToken(@floatFromInt(message));
    } else if (T == f32) {
        receiveNumberToken(message);
    }
}

fn closeExpressionAndGetResult() JSResult {
    var result = JSResult{
        .value = 0,
        .str = undefined,
        .valueType = 0,
    };

    closeExpression();

    result.valueType = u8Buffer[0];

    if (result.valueType == TYPE_INT_8) {
        result.value = u8Buffer[1];
    }
    if (result.valueType == TYPE_STR) {
        std.mem.copy(u8, result.str[0..], u8Buffer[1..]);
    }

    return result;
}

fn sendTokenString(message: []const u8) void {
    sendToken([]const u8, message);
}

fn debug(comptime T: type, message: T) void {
    openExpression();
    sendToken(str, "console.log");
    sendToken(T, message);
    _ = closeExpression();
}

export fn main() void {
    // Some math
    openExpression();
    sendToken(str, "MathOps.add");
    sendToken(u8, 40);
    openExpression();
    sendToken(str, "MathOps.add");
    sendToken(u8, 1);
    openExpression();
    sendToken(str, "MathOps.mul");
    openExpression();
    sendToken(str, "Math.random");
    closeExpression();
    sendToken(u8, 5);
    sendToken(u8, 1);
    closeExpression();
    const result1 = closeExpressionAndGetResult();
    const result2 = closeExpressionAndGetResult();

    debug(str, "Result 1");
    debug(u8, result1.asInt());
    debug(str, "Result 2");
    debug(u8, result2.asInt());

    // Some strings
    openExpression();
    sendToken(str, "randomString");
    const result = closeExpressionAndGetResult();
    debug(usize, result.str.len);
    debug(str, result.str[0..12 :0]);
}
