# libgrpc packages for the Zig build system

Status: Work in progress

## Bump dependencies

When bumping upstream version, also bump dependencies. Example:

```shell
zig fetch --save=upstream  git+https://github.com/grpc/grpc#v1.76.0
zig fetch --save=abseil    git+https://github.com/abseil/abseil-cpp#20250512.1
zig fetch --save=re2       git+https://github.com/google/re2#2022-04-01
zig fetch --save=boringssl git+https://github.com/google/boringssl#c63fadbde60a2224c22189d14c4001bbd2a3a629
zig fetch --save=cares     git+https://github.com/c-ares/c-ares#v1.34.5
zig fetch --save=gtest     git+https://github.com/google/googletest#v1.17.0
zig fetch --save=zlib      git+https://github.com/madler/zlib#v1.3.1
```
