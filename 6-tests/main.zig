const std = @import("std");

fn add(a: i32, b: i32) i32 {
    return a + b;
}

fn broken_add(a: i32, b: i32) i32 {
    return a + b + 42;
}

test "Should perform addition" {
    const result = add(3, 3);
    try std.testing.expectEqual(result, 6);
}

test "Should perform addition (broken)" {
    const result = broken_add(3, 3);
    try std.testing.expectEqual(result, 6);
}
