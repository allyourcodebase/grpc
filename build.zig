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
    const zlib = b.dependency("zlib", .{});

    const libs_step = b.step("dependencies", "Install libraries libgrpc depends on");

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
    caresmod.addCMacro("_HAS_EXCEPTIONS", "0");
    caresmod.addCMacro("NOMINMAX", "1");
    caresmod.addCMacro("HAVE_CONFIG_H", "1");
    caresmod.addIncludePath(upstream.path("third_party/cares"));
    caresmod.addIncludePath(cares.path("include"));
    caresmod.addIncludePath(cares.path("src/lib"));
    caresmod.addIncludePath(cares.path("src/lib/include"));
    caresmod.addIncludePath(upstream.path("third_party/cares").path(b, cares_config));
    libcares.installHeadersDirectory(cares.path("include"), "", .{});
    libcares.installHeader(upstream.path("third_party/cares/ares_build.h"), "ares_build.h");
    libcares.installHeader(upstream.path("third_party/cares").path(b, cares_config).path(b, "ares_config.h"), "ares_config.h");
    libs_step.dependOn(&b.addInstallArtifact(libcares, .{}).step);

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
    abseilmod.addIncludePath(abseil.path(""));
    libabseil.installHeadersDirectory(abseil.path("absl"), "absl", .{
        .include_extensions = &.{ ".h", ".inc" },
    });
    libs_step.dependOn(&b.addInstallArtifact(libabseil, .{}).step);

    // UTF8-range
    const utf8mod = b.createModule(.{ .target = target, .optimize = optimize });
    const libutf8 = b.addLibrary(.{ .name = "utf8-range", .root_module = utf8mod });
    utf8mod.addCSourceFiles(.{
        .root = upstream.path("third_party/utf8_range"),
        .files = &file_lists.libgrpc_third_party_utf8_range,
        .flags = &c_flags,
    });
    libutf8.installHeader(
        upstream.path("third_party/utf8_range/utf8_range.h"),
        "utf8_range.h",
    );
    libs_step.dependOn(&b.addInstallArtifact(libutf8, .{}).step);

    // upb
    const upbmod = b.createModule(.{ .target = target, .optimize = optimize });
    const libupb = b.addLibrary(.{ .name = "upb", .root_module = upbmod });
    upbmod.addCSourceFiles(.{
        .root = upstream.path("third_party/upb"),
        .files = &file_lists.libgrpc_third_party_upb,
        .flags = &c_flags,
    });
    // Those are all generated upb files
    upbmod.addCSourceFiles(.{
        .root = upstream.path("src/core"),
        .files = &file_lists.libgrpc_src_core_c,
        .flags = &c_flags,
    });
    upbmod.addIncludePath(upstream.path("third_party/upb"));
    upbmod.addIncludePath(upstream.path("src/core/ext/upb-gen"));
    upbmod.addIncludePath(upstream.path("src/core/ext/upbdefs-gen"));
    upbmod.linkLibrary(libutf8);
    libs_step.dependOn(&b.addInstallArtifact(libupb, .{}).step);

    // BoringSSL
    const sslmod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    const libssl = b.addLibrary(.{ .name = "ssl", .root_module = sslmod });
    sslmod.addCSourceFiles(.{
        .root = boringssl.path("src"),
        .files = &file_lists.libboringssl_src,
        .flags = &(cxx_flags ++ .{"-fno-exceptions"}),
    });
    sslmod.addCMacro("OPENSSL_NO_ASM", "1");
    sslmod.addCMacro("_GNU_SOURCE", "1");
    sslmod.addCMacro("_HAS_EXCEPTIONS", "0");
    sslmod.addCMacro("NOMINMAX", "1");
    sslmod.addIncludePath(boringssl.path("src/include"));
    libssl.installHeadersDirectory(boringssl.path("src/include/openssl"), "openssl", .{});
    libs_step.dependOn(&b.addInstallArtifact(libssl, .{}).step);

    // zlib
    const zmod = b.createModule(.{ .target = target, .optimize = optimize });
    const libz = b.addLibrary(.{ .name = "z", .root_module = zmod });
    zmod.addCSourceFiles(.{
        .root = zlib.path(""),
        .files = &file_lists.libz_src,
        .flags = &c_flags,
    });
    zmod.addCMacro("HAVE_UNISTD_H", "1");
    libs_step.dependOn(&b.addInstallArtifact(libz, .{}).step);

    // Address Sorting
    const addrsort = b.createModule(.{ .target = target, .optimize = optimize });
    const libaddrsort = b.addLibrary(.{ .name = "addresssorting", .root_module = addrsort });
    addrsort.addCSourceFiles(.{
        .root = upstream.path("third_party/address_sorting"),
        .files = &file_lists.libgrpc_third_party_address_sorting,
        .flags = &c_flags,
    });
    addrsort.addIncludePath(upstream.path("third_party/address_sorting/include"));
    libaddrsort.installHeadersDirectory(upstream.path("third_party/address_sorting/include/address_sorting"), "address_sorting", .{});
    libs_step.dependOn(&b.addInstallArtifact(libaddrsort, .{}).step);

    // re2
    const re2mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    const libre2 = b.addLibrary(.{ .name = "re2", .root_module = re2mod });
    re2mod.addCSourceFiles(.{
        .root = re2.path(""),
        .files = &file_lists.libgrpc_third_party_re2,
        .flags = &cxx_flags,
    });
    re2mod.addIncludePath(re2.path(""));
    libre2.installHeadersDirectory(re2.path("re2"), "re2", .{});
    libs_step.dependOn(&b.addInstallArtifact(libre2, .{}).step);

    // Core library
    const grpc = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    const libgrpc = b.addLibrary(.{ .name = "grpc", .root_module = grpc });

    grpc.addCSourceFiles(.{
        .root = upstream.path("src/core"),
        .files = &file_lists.libgrpc_src_core_cpp,
        .flags = &(cxx_flags ++ .{"-fno-exceptions"}),
    });
    grpc.addIncludePath(upstream.path("include"));
    grpc.addIncludePath(upstream.path(""));
    grpc.addIncludePath(upstream.path("src/core/ext/upb-gen"));
    grpc.addIncludePath(upstream.path("src/core/ext/upbdefs-gen"));
    grpc.addIncludePath(upstream.path("third_party/xxhash"));
    grpc.addIncludePath(upstream.path("third_party/upb"));
    grpc.linkLibrary(libcares);
    grpc.linkLibrary(libabseil);
    grpc.linkLibrary(libupb);
    grpc.linkLibrary(libssl);
    grpc.linkLibrary(libz);
    grpc.linkLibrary(libaddrsort);
    grpc.linkLibrary(libre2);
    if (target.result.os.tag.isDarwin()) {
        grpc.linkFramework("CoreFoundation", .{});
        grpc.addCMacro("OSATOMIC_USE_INLINED", "1");
    }
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
                .file = upstream.path("test/core/slice/c_slice_buffer_test.cc"),
                .flags = &cxx_flags,
            });
            mod.addIncludePath(upstream.path(""));
            mod.linkLibrary(libgtest);
            mod.linkLibrary(libabseil);
            try tests.append(b.allocator, .{ .name = "c_slice_buffer", .mod = mod });
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
        const grpc_capi = b.addTranslateC(.{
            .root_source_file = try include_all.getDirectory().join(b.allocator, "grpc_api.h"),
            .target = target,
            .optimize = optimize,
        });
        grpc_capi.addIncludePath(upstream.path("include"));

        const bindings = grpc_capi.addModule("cgrpc");
        bindings.linkLibrary(libgrpc);
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
