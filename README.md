# libgrpc packages for the Zig build system



## Bump dependencies

When bumping upstream version, also bump dependencies. Example:

```shell
zig fetch --save=upstream git+https://github.com/grpc/grpc#v1.76.0
zig fetch --save=abseil   git+https://github.com/abseil/abseil-cpp#20250512.1
zig fetch --save=re2      git+https://github.com/google/re2#2022-04-01
```
