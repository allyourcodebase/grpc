const std = @import("std");
const file_lists = @import("generated.zig");

const Build = std.Build;
const ExecutableList = std.ArrayList(struct { name: []const u8, mod: *Build.Module });

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

    // C-Ares Library
    const caresmod = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });
    const libcares = b.addLibrary(.{ .name = "cares", .root_module = caresmod });
    const cares_config = switch (target.result.os.tag) {
        .linux => "config_linux",
        .macos, .ios, .tvos, .watchos => "config_darwin",
        .freebsd => "config_freebsd",
        .openbsd => "config_openbsd",
        else => return error.OsNotSupported,
    };
    caresmod.addCSourceFiles(.{
        .root = cares.path(""),
        .files = &file_lists.libcares_src,
        .flags = &c_flags,
    });
    caresmod.addCMacro("_GNU_SOURCE", "1");
    caresmod.addCMacro("_HAS_EXCEPTIONs", "0");
    caresmod.addCMacro("HAVE_CONFIG_H", "1");
    caresmod.addIncludePath(upstream.path("third_party/cares"));
    caresmod.addIncludePath(cares.path("include"));
    caresmod.addIncludePath(cares.path("src/lib"));
    caresmod.addIncludePath(cares.path("src/lib/include"));
    caresmod.addIncludePath(upstream.path("third_party/cares").path(b, cares_config));
    libcares.installHeadersDirectory(cares.path("include"), "", .{});
    libcares.installHeader(upstream.path("third_party/cares/ares_build.h"), "ares_build.h");
    libcares.installHeader(upstream.path("third_party/cares").path(b, cares_config).path(b, "ares_config.h"), "ares_config.h");
    b.installArtifact(libcares);

    // Abseil
    const abseilmod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    const libabseil = b.addLibrary(.{ .name = "abseil", .root_module = abseilmod });
    abseilmod.addCSourceFiles(.{
        .root = abseil.path(""),
        .files = &file_lists.libgrpc_third_party_abseil_cpp,
        .flags = &cxx_flags,
    });
    abseilmod.addCMacro("OSATOMIC_USE_INLINED", "1");
    abseilmod.addIncludePath(abseil.path(""));
    libabseil.installHeadersDirectory(abseil.path(""), "", .{});
    b.installArtifact(libabseil);

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
    grpc.addIncludePath(upstream.path("third_party/address_sorting/include"));
    grpc.addIncludePath(upstream.path("third_party/xxhash"));
    grpc.addIncludePath(abseil.path(""));
    grpc.addIncludePath(re2.path(""));
    grpc.addIncludePath(boringssl.path("src/include"));
    grpc.linkLibrary(libcares);
    libgrpc.installHeadersDirectory(upstream.path("include/grpc"), "grpc", .{});
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
    libgtest.installHeadersDirectory(gtest.path("googletest/include"), "", .{});

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
            client_idle.linkLibrary(libgtest);
            try tests.append(b.allocator, .{ .name = "idle_filter_state", .mod = client_idle });
        }
        {
            const mod = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libcpp = true,
            });
            mod.addCSourceFile(.{
                .file = upstream.path("test/core/address_utils/parse_address_test.cc"),
                .flags = &cxx_flags,
            });
            mod.addIncludePath(upstream.path(""));
            mod.addIncludePath(abseil.path(""));
            mod.linkLibrary(libgtest);
            try tests.append(b.allocator, .{ .name = "parse_address", .mod = mod });
        }

        for (tests.items) |ite| {
            const exe = b.addExecutable(.{ .name = ite.name, .root_module = ite.mod });
            const install_exe = b.addInstallArtifact(exe, .{});
            const run_exe = b.addRunArtifact(exe);
            ite.mod.linkLibrary(libgrpc);
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
