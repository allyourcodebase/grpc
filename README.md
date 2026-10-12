# gRPC packaged for the Zig build system

## Status

| Architecture \ OS | Linux | macOS |
|:------------------|:-----:|:-----:|
| x86_64            | ✅    | ✅    |
| arm 64            | ✅    | ✅    |

| Refname  | libGRPC version         | Core version | Zig `0.17.x` | Zig `0.16.x` | Zig `0.15.x` |
|:---------|:------------------------|-------------:|:------------:|:------------:|:------------:|
| `master` | `v1.85.0-pre1` "googol" |     `58.0.0` | ✅           | ✅           | ✅           |
| `1.84.0` | `v1.84.0` "gimbal"      |     `56.0.0` | ✅           | ✅           | ✅           |

<details>
<summary>Older versions</summary>

| Refname    | libGRPC version        | Core version | Zig `0.17.x` | Zig `0.16.x` | Zig `0.15.x` |
|:-----------|:-----------------------|-------------:|:------------:|:------------:|:------------:|
| `1.83.1`   | `v1.83.1` "garden"     |     `56.0.0` | ✅           | ✅           | ✅           |
| `1.82.2`   | `v1.82.2` "glacier"    |     `55.0.0` | ✅           | ✅           | ✅           |
| `1.81.1`   | `v1.81.1` "graphic"    |     `54.0.0` | ✅           | ✅           | ✅           |
| `1.80.0`   | `v1.80.0` "glimmering" |     `53.0.0` | ✅           | ✅           | ✅           |
| `1.78.1+1` | `v1.78.1` "gusty"      |     `52.0.0` | ✅           | ✅           | ✅           |
| `1.76.0+2` | `v1.76.0` "genuine"    |     `51.0.0` | ✅           | ✅           | ✅           |

</details>

## Use

Add the dependency to your `build.zig.zon` by running the following command:
```shell
zig fetch --save git+https://github.com/allyourcodebase/grpc#master
```

Simple usage from your `build.zig`:
```zig
const grpc = b.dependency("grpc", .{
	.target = target,
	.optimize = optimize,
});

mod.addImport("cgrpc", grpc.module("cgrpc"));
```

Advanced usage, for C users or to choose the linking mode:
```zig
const grpc_link_mode = b.option(std.builtin.LinkMode, "grpc_link_mode", "Link the gRPC core library statically or dynamically");

const grpc = b.dependency("grpc", .{
	.target = target,
	.optimize = optimize,
	.link_mode = grpc_link_mode,
	.pic = true, // needed to link a static libgrpc into a shared library or a PIE, defaults to true only when dynamic
});
const libgrpc_built = if (b.systemIntegrationOption("grpc", .{})) null else grpc.artifact("grpc");

// to use from Zig:
mod.addImport("cgrpc", grpc.module("cgrpc"));
if (libgrpc_built) |libgrpc| {
	if (libgrpc.isDynamicLibrary())
		b.installArtifact(libgrpc);
}

// to use from C:
if (libgrpc_built) |libgrpc| {
	exe.root_module.linkLibrary(libgrpc);
	if (libgrpc.isDynamicLibrary()) {
		b.installArtifact(libgrpc);
		exe.root_module.addRPathSpecial(if (target.result.os.tag.isDarwin()) "@executable_path/../lib" else "$ORIGIN/../lib");
	}
} else {
	exe.root_module.linkSystemLibrary("grpc", .{});
}
```

## Options

```
  -Dlink_mode=[enum]           Compile static or dynamic libraries. Defaults to static
                                 Supported Values:
                                   static
                                   dynamic
  -Dpic=[bool]                 Produce Position Independent Code. Defaults to true when link_mode is dynamic
```

## System Integration

By default, libgrpc is built from source, to allow cross-compilation and reproducibility.

However, for security reasons, or to not waste disk / CPU / time re-compiling a huge library already installed on the system, it might be preferable to use the system's `.so`/`.dylib`.

For this purpose, a system integration is available. When building the final binary:

```shell
zig build -fsys=grpc
```

will use the system's gRPC library. The `cgrpc` module then links it, and nothing gets downloaded or built.

The `grpc` artifact is not available in this mode, which is why the [advanced usage](#use) checks the same option.
As system integration options are shared by the whole build, they get the same answer as this package.
