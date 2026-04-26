#!/bin/bash
# Parameter: New libgrpc version, without the v prefix, e.g. "1.80.0"
set -euo pipefail

VERSION=$1
URL="https://github.com/grpc/grpc"
GIT_REF="v$VERSION"
FETCH_ARG="git+$URL#$GIT_REF"

# 1. Fetch the new version
HASH=$(zig fetch $FETCH_ARG)
zig fetch --save=upstream $FETCH_ARG

# 2. Re-generate the file lists
uv run python generate.py < zig-pkg/$HASH/Makefile | zig fmt --stdin > generated.zig

# 3. Bump the package version
sed "s|\([.]version *= *\).*|\1\"$VERSION\",|" build.zig.zon > tmp.zon
mv tmp.zon build.zig.zon
