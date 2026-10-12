# Contributing

Guidance for working on this repository.

## Project

gRPC's core library (libgrpc) packaged for the Zig build system. It exposes:
- the `cgrpc` module: translate-c bindings of `grpc/grpc.h`, `grpc/credentials.h` and `grpc/byte_buffer_reader.h`, linked to libgrpc
- the `grpc` artifact: the library itself, with its headers installed

Supported: Zig 0.15.x to master (see the CI matrix), Linux and macOS on x86_64 and aarch64.

Files:
- `build.zig`: everything; libgrpc's bundled dependencies (c-ares, abseil, upb, utf8-range, BoringSSL, zlib, address-sorting, re2) are built as static libraries linked into libgrpc
- `generated.zig`: source file lists, generated from upstream's Makefile by `generate.py` through `update.sh`, never edited by hand
- `UPDATE.md`: how to bump gRPC and its dependencies. `zig fetch --save=<name>` keeps the `.lazy = true` of an existing dependency

## Commands

```shell
zig build                 # Build and install libgrpc
zig build dependencies    # Build and install the bundled libraries
zig build examples        # Build the test programs
zig build test            # Run the test programs

cd example && zig build run   # Build and run the README's advanced usage, from Zig and C
```

Options:
- `-Dlink_mode=static|dynamic`: static by default
- `-Dpic=bool`: defaults to true when dynamic
- `-fsys=grpc`: use the system's libgrpc, nothing is built or downloaded

A Debug libgrpc build takes about 2 minutes on an Apple Silicon laptop, 18 to 30 minutes on GitHub runners.

## Design constraints

**System integration**: with `-fsys=grpc`, `cgrpc` links the system's libgrpc and `build()` returns before declaring anything else, so the `grpc` artifact does not exist. Dependents check `b.systemIntegrationOption("grpc", .{})` themselves (these options are shared by the whole build) before using the artifact.

**Lazy dependencies**: all dependencies are lazy, so that `-fsys=grpc` downloads nothing.
- Use `b.lazyDependency()`: `b.dependency()` panics on lazy dependencies before Zig 0.17, and `b.dependencyLazy()` only exists since 0.17.
- All dependencies are requested before returning on a missing one, so that they are fetched in a single round.
- `cgrpc` and the `grpc` artifact are declared before that early return: on the first configuration pass, dependents look them up, and `Dependency.module()`/`Dependency.artifact()` panic when they are missing.

**`cgrpc`** links the system library with `Module.linkSystemLibrary`, not `TranslateC.linkSystemLibrary`, which does not exist in Zig 0.15 (and `TranslateC.addModule` copies the latter's libraries when creating the module, so it would have to be called first).

**Dynamic linking**:
- `cgrpc` adds the rpath `$ORIGIN/../lib` (`@executable_path/../lib` on macOS), so binaries find libgrpc installed in `lib/` next to `bin/`. C users linking the artifact add it themselves (see the README).
- Exported symbols: the bundled libraries are compiled with `bundled_c_flags`/`bundled_cxx_flags` (`-fvisibility=hidden`), so they cannot conflict with other versions loaded by the same program. gRPC's own sources keep default visibility, with `-fvisibility-inlines-hidden`, so that the test programs can use its internals (`grpc_core::`...). The test programs also use abseil directly, so they link it themselves.
- On ELF, a version script also hides what visibility cannot: c-ares' API, explicitly marked `visibility("default")`, and the C++ runtime's `operator new`/`delete` (`_Znw*`, `_Zna*`, `_Zdl*`, `_Zda*`). It is a denylist on purpose: an allowlist on demangled `grpc_*` names drops vtables, typeinfos and templates, and broke the test programs (`vtable for grpc_core::promise_detail::Unwakeable`). lld treats quoted version script names as exact matches, not globs.
- Zig's Mach-O linker ignores version scripts and has no exported symbols list, so c-ares and `operator new`/`delete` stay exported on macOS (harmless thanks to two-level namespaces).
- Expected result: no BoringSSL, zlib, upb or re2 functions exported, and no c-ares on Linux. Abseil/libc++ template instantiations used by gRPC remain, in versioned namespaces (`absl::lts_...`, `std::__1`).

**Compatibility**: everything used exists from Zig 0.15.2 to master (`lazyDependency`, `systemIntegrationOption`, `Module.linkSystemLibrary`, `Module.addRPathSpecial`, `Compile.setVersionScript`, `addWriteFiles`, `Target.ofmt`). Check before using newer APIs. Zig 0.15.2's build runner does not link on macOS 26 (`__availability_version_check`): test 0.15 through CI.

## Zig build system notes

- Since Zig 0.16, packages are extracted into `zig-pkg/` inside the build root (override with `ZIG_LOCAL_PKG_DIR`). Lazy dependencies are never downloaded unless requested, but are extracted if their tarball is already in the global cache.
- `null` values in `b.dependency()` arguments are skipped, leaving this package's defaults.
- Cache keys include the paths passed to the compiler, and paths under the build root are passed relative to it. Two projects sharing a cache only reuse each other's libgrpc if both the package directory and the cache directory are outside both build roots.

## CI

- Every step passes `-Dlink_mode=dynamic`, so the test programs reuse the same libgrpc, and exercise the dynamic library's exports.
- Every step also passes `-Dcpu=baseline`: the target CPU is part of every cache key, and the native CPU varies between runners, so without it the cache is rarely reused.
- `mlugg/setup-zig` caches `$GITHUB_WORKSPACE/.zig-cache` per job name and exact Zig version. Its default 2 GiB `cache-size-limit` empties the cache after a Debug libgrpc build (about 2.5 GB, 0.45 GB compressed), hence `cache-size-limit: 4096`.
- The 0.17.0 and master jobs miss the cache anyway: since 0.17, a file whose metadata changed (as after extracting packages on a fresh runner) is recompiled even when its contents did not, see https://codeberg.org/ziglang/zig/issues/37200.

## Dependents

`cgrpc_wrapper` (github.com/agagniere/cgrpc_wrapper) is the main dependent. Changes here only reach it through a new commit pinned in its `build.zig.zon`; to test before that, point its dependency to this checkout with `.path`.
