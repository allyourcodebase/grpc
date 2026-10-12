const std = @import("std");
const c = @import("cgrpc");

pub fn main() void {
    c.grpc_init();
    defer c.grpc_shutdown();
    std.debug.print("gRPC core {s} (from Zig)\n", .{c.grpc_version_string()});
}
