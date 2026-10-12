const std = @import("std");

/// Uses this package the way the README's advanced usage describes, from both Zig and C
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const grpc_link_mode = b.option(std.builtin.LinkMode, "grpc_link_mode", "Link the gRPC core library statically or dynamically");

    const grpc = b.dependency("grpc", .{
        .target = target,
        .optimize = optimize,
        .link_mode = grpc_link_mode,
    });
    const libgrpc_built = if (b.systemIntegrationOption("grpc", .{})) null else grpc.artifact("grpc");
    const run_step = b.step("run", "Run the example programs");

    // Common for both Zig and C:
    if (libgrpc_built) |libgrpc| {
        if (libgrpc.isDynamicLibrary()) b.installArtifact(libgrpc);
    }

    { // From Zig
        const zig_mod = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "cgrpc", .module = grpc.module("cgrpc") }},
        });
        const zig_exe = b.addExecutable(.{ .name = "zig_example", .root_module = zig_mod });

        b.installArtifact(zig_exe);
        run_step.dependOn(&b.addRunArtifact(zig_exe).step);
    }

    { // From C
        const c_mod = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        const c_exe = b.addExecutable(.{ .name = "c_example", .root_module = c_mod });

        c_mod.addCSourceFile(.{ .file = b.path("main.c") });
        if (libgrpc_built) |libgrpc| {
            c_mod.linkLibrary(libgrpc);
            if (libgrpc.isDynamicLibrary()) {
                // b.installArtifact(libgrpc); // if your use case is C only you can install it directly
                c_mod.addRPathSpecial(if (target.result.os.tag.isDarwin()) "@executable_path/../lib" else "$ORIGIN/../lib");
            }
        } else {
            c_mod.linkSystemLibrary("grpc", .{});
        }
        b.installArtifact(c_exe);
        run_step.dependOn(&b.addRunArtifact(c_exe).step);
    }
}
