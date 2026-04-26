# Bumping the gRPC version

For this package maintainers: How to update the package for new upstream releases

## Bump dependencies

Check upstream and copy the pinned versions

```shell
zig fetch --save=abseil    git+https://github.com/abseil/abseil-cpp#20250512.1
zig fetch --save=re2       git+https://github.com/google/re2#2022-04-01
zig fetch --save=boringssl git+https://github.com/google/boringssl#2b44a3701a4788e1ef866ddc7f143060a3d196c9
zig fetch --save=cares     git+https://github.com/c-ares/c-ares#v1.34.5
zig fetch --save=gtest     git+https://github.com/google/googletest#v1.17.0
zig fetch --save=zlib      git+https://github.com/madler/zlib#v1.3.1
```

## Bump upstream version

A script is provided to
1. Fetch the version
2. Re-generate file lists
3. Bump the package version

**Requires**: [uv](https://docs.astral.sh/uv/getting-started/installation/)

```shell
./update.sh 1.80.0
```
