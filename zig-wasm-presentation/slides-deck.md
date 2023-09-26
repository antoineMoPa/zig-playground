---
marp: false
theme: default
paginate: true
---

# Zig playground

I played with zig a in a web assembly context.

---

# Philosophy

https://ziglang.org/documentation/master/#Zen

> [...]
> - Runtime crashes are better than bugs.
> - Compile errors are better than runtime crashes.
> - Together we serve the users.

---

# Hello world

main.zig

```c
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, world!", .{});
}
```

Building:

```
zig build-exe main.zig
```

Result:

```bash
antoine@MacBook-Air-de-Antoine:~/prog/zig-playground/9-hello-world-non-wasm $ ./main
Hello, world!
```

---

# String interpolation

```c
try stdout.print("Hello, {s}!\n", .{"world"});
```

---

# Testing with zig

```c
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

```


---

# Building for the browser

add.zig

```c
extern fn print(i32) void;

export fn add(a: i32, b: i32) void {
    print(a + b);
}
```

Building:

```
zig build-lib add.zig -target wasm32-freestanding -dynamic -rdynamic
```

---

# Result

add.wasm
```c
antoine@MacBook-Air-de-Antoine:~/prog/zig-playground/1-add-wasm $ cat add.wasm
envprint	A???
                    memoryadd
??#????!A!  k! $????    6
                         A!  H!  j!  H s!	A!

q!
  @
A????!
A!A????!
  ????
       ????A!  j! $????

```

---

# Using in browser

```javascript
<script type="module">
  const importObject = {
      env: {
          print: (message) => console.log(message),
      }
  };

  WebAssembly.instantiateStreaming(fetch("add.wasm"), importObject).then(
      (results) => {
          console.log(results.instance.exports.add(4, 5));
      },
  );
</script>
```
