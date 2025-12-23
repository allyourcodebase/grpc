const std = @import("std");
const file_lists = @import("generated.zig");

const Build = std.Build;
const ExecutableList = std.ArrayList(*Build.Step.Compile);

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Dependencies
    const upstream = b.dependency("upstream", .{});
    const abseil = b.dependency("abseil", .{});
    const re2 = b.dependency("re2", .{});
    const boringssl = b.dependency("boringssl", .{});
    const cares = b.dependency("cares", .{});
    const gtest = b.dependency("gtest", .{});

    // Core library
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

    // Googletest library
    const gtestmod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    const libgtest = b.addLibrary(.{ .name = "gtest", .root_module = gtestmod });
    gtestmod.addCSourceFiles(.{
        .root = gtest.path("googletest/src"),
        .files = &gtest_srcs,
        .flags = &cxx_flags,
    });
    gtestmod.addIncludePath(gtest.path("googletest/include"));
    gtestmod.addIncludePath(gtest.path("googletest"));

    { // Build tests to ensure no symbols are missing
        const example_step = b.step("examples", "Build example programs");
        const test_step = b.step("test", "Run test programs");

        var tests: ExecutableList = try .initCapacity(b.allocator, 64);

        {
            const client_idle = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libcpp = true,
            });
            client_idle.addCSourceFile(.{
                .file = upstream.path("test/core/client_idle/idle_filter_state_test.cc"),
                .flags = &cxx_flags,
            });
            client_idle.addIncludePath(upstream.path(""));
            client_idle.addIncludePath(upstream.path("include"));
            client_idle.addIncludePath(gtest.path("googletest/include"));
            client_idle.linkLibrary(libgtest);
            client_idle.linkLibrary(libgrpc);
            try tests.append(b.allocator, b.addExecutable(.{ .name = "idle_filter_state", .root_module = client_idle }));
        }

        for (tests.items) |exe| {
            const install_exe = b.addInstallArtifact(exe, .{});
            const run_exe = b.addRunArtifact(exe);
            example_step.dependOn(&install_exe.step);
            test_step.dependOn(&run_exe.step);
        }
    }

    { // Generate bindings from grpc C headers
        const include_all = b.addWriteFile("grpc_api.h",
            \\#include <grpc/grpc.h>
            \\#include <grpc/credentials.h>
            \\#include <grpc/byte_buffer_reader.h>
        );
        const binding = b.addTranslateC(.{
            .root_source_file = try include_all.getDirectory().join(b.allocator, "grpc_api.h"),
            .target = target,
            .optimize = optimize,
        });
        binding.addIncludePath(upstream.path("include"));
        _ = binding.addModule("cgrpc");
    }
}

const common_flags = .{ "-Wall", "-Wextra" };
const c_flags = common_flags ++ .{"-std=c11"};
const cxx_flags = common_flags ++ .{"-std=c++17"};

const gtest_srcs = .{
    "gtest-assertion-result.cc",
    "gtest-death-test.cc",
    "gtest-filepath.cc",
    "gtest-matchers.cc",
    "gtest-port.cc",
    "gtest-printers.cc",
    "gtest-test-part.cc",
    "gtest-typed-test.cc",
    "gtest.cc",
};
