# gRPC packaged for the Zig build system

## Status

| Architecture \ OS | Linux | MacOS |
|:------------------|:-----:|:-----:|
| x86_64            | ✅    | ✅    |
| arm 64            | ✅    | ✅    |

| Refname    | libGRPC version        | Core version | Zig `0.17-dev` | Zig `0.16.x` | Zig `0.15.x` |
|:-----------|:-----------------------|-------------:|:--------------:|:------------:|:------------:|
| `1.82.2`   | `v1.82.2` "glacier"    |     `55.0.0` | ✅             | ✅           | ✅           |
| `1.81.1`   | `v1.81.1` "graphic"    |     `54.0.0` | ✅             | ✅           | ✅           |
| `1.80.0`   | `v1.80.0` "glimmering" |     `53.0.0` | ✅             | ✅           | ✅           |
| `1.78.1+1` | `v1.78.1` "gusty"      |     `52.0.0` | ✅             | ✅           | ✅           |
| `1.76.0+2` | `v1.76.0` "genuine"    |     `51.0.0` | ✅             | ✅           | ✅           |

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
