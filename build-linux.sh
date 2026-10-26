#!/bin/sh
# bacontsu: build studiomdl with make, picking an architecture the toolchain can actually target
# usage: ./build-linux.sh [extra make arguments, e.g. USER_FLAGS=-O3]
set -e
cd "$(dirname "$0")"

CC=${CC:-cc}

# the 32-bit target needs gcc-multilib / libc6-dev-i386, so fall back to 64-bit when it is missing
if printf 'int main(void){return 0;}\n' | $CC -m32 -x c - -o /dev/null 2>/dev/null; then
	ARCH=-m32
else
	ARCH=-m64
	echo "32-bit toolchain not available, building 64-bit (-m64)"
fi

exec make CC="$CC" ARCH="$ARCH" "$@"
