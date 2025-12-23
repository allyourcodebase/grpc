const std = @import("std");
const file_lists = @import("generated.zig");

const Build = std.Build;
const Dependency = std.Build.Dependency;

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("upstream", .{});
    const abseil = b.dependency("abseil", .{});
    const re2 = b.dependency("re2", .{});
    const boringssl = b.dependency("boringssl", .{});
    const cares = b.dependency("cares", .{});

    const grpc = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    const libgrpc = b.addLibrary(.{ .name = "grpc", .root_module = grpc });

    grpc.addCSourceFiles(.{
        .root = upstream.path("src/core"),
        .files = &file_lists.libgrpc_src_core_c,
        .flags = &c_flags,
    });
    grpc.addCSourceFiles(.{
        .root = upstream.path("src/core"),
        .files = &file_lists.libgrpc_src_core_cpp,
        .flags = &(cxx_flags ++ .{"-fno-exceptions"}),
    });
    grpc.addCMacro("OSATOMIC_USE_INLINED", "1");
    grpc.addIncludePath(upstream.path("include"));
    grpc.addIncludePath(upstream.path(""));
    grpc.addIncludePath(upstream.path("src/core/ext/upb-gen"));
    grpc.addIncludePath(upstream.path("src/core/ext/upbdefs-gen"));
    grpc.addIncludePath(upstream.path("third_party/upb"));
    grpc.addIncludePath(upstream.path("third_party/cares"));
    grpc.addIncludePath(upstream.path("third_party/address_sorting/include"));
    grpc.addIncludePath(upstream.path("third_party/xxhash"));
    grpc.addIncludePath(abseil.path(""));
    grpc.addIncludePath(re2.path(""));
    grpc.addIncludePath(boringssl.path("src/include"));
    grpc.addIncludePath(cares.path("include"));
    b.installArtifact(libgrpc);
}

const common_flags = .{
    "-Wall",
    "-Wextra",
};

const c_flags = common_flags ++ .{"-std=c11"};
const cxx_flags = common_flags ++ .{"-std=c++17"};
