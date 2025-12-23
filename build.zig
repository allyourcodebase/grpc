const std = @import("std");
const file_lists = @import("generated.zig");

const Build = std.Build;
const Dependency = std.Build.Dependency;

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("upstream", .{});

    const grpc = b.createModule(.{ .target = target, .optimize = optimize });
    const libgrpc = b.addLibrary(.{
        .name = "grpc",
        .root_module = grpc,
    });

    grpc.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &file_lists.libgrpc_src,
        .flags = &CFLAGS,
    });
    grpc.addCMacro("OSATOMIC_USE_INLINED", "1");

    b.installArtifact(libgrpc);
}

const CFLAGS = .{
    "-Wall",
    "-Wextra",
    "-Wmissing-prototypes",
};
