# gRPC packaged for the Zig build system

## Status

| Architecture \ OS | Linux | MacOS |
|:------------------|:-----:|:-----:|
| x86_64            | ✅    | ✅    |
| arm 64            | ✅    | ✅    |

| Refname     | libGRPC version | Core version | Zig `0.16.x` | Zig `0.15.x` |
|-------------|-----------------|--------------|:------------:|:------------:|
| `grpc-1.78` | `v1.78.0-pre2`  | `52.0.0`     | ✅           | ✅           |
| `1.76.0+2`  | `v1.76.0`       | `51.0.0`     | ✅           | ✅           |

## Use

Add the dependency to your `build.zig.zon` by running the following command:
```zig
zig fetch --save git+https://github.com/allyourcodebase/grpc#master
```

Then, in your `build.zig`:
```zig
const grpc = b.dependency("grpc", {
	.target = target,
	.optimize = optimize,
	.link_mode = .dynamic,
	.pic = true,
});

// to use from Zig:
mod.addImport("cgrpc", grpc.module("cgrpc"));

// to use from C:
exe.linkLibrary(grpc.artifact("grpc"));
```

## Options

```
  -Dlink_mode=[enum]           Compile static or dynamic libraries. Defaults to dynamic
                                 Supported Values:
                                   static
                                   dynamic
  -Dpic=[bool]                 Produce Position Independent Code. Defaults to true when link_mode is dynamic
```

## Bump dependencies

When bumping upstream version, also bump dependencies. Example:

```shell
zig fetch --save=upstream  git+https://github.com/grpc/grpc#v1.78.0-pre2
zig fetch --save=abseil    git+https://github.com/abseil/abseil-cpp#20250512.1
zig fetch --save=re2       git+https://github.com/google/re2#2022-04-01
zig fetch --save=boringssl git+https://github.com/google/boringssl#c63fadbde60a2224c22189d14c4001bbd2a3a629
zig fetch --save=cares     git+https://github.com/c-ares/c-ares#v1.34.5
zig fetch --save=gtest     git+https://github.com/google/googletest#v1.17.0
zig fetch --save=zlib      git+https://github.com/madler/zlib#v1.3.1
```
