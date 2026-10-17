#!/usr/bin/env bash

# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2024-2025 <Nitrux Latinoamericana S.C. <hello@nxos.org>>


# -- Exit on errors.

set -euo pipefail

# -- Prepare source.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"
PACKAGE_VERSION="${PACKAGE_VERSION:?PACKAGE_VERSION must be supplied by CI}"
TARGET_ARCH="${TARGET_ARCH:-$(dpkg --print-architecture)}"

# -- Download Source

git clone --depth 1 --branch "${CLIP_BRANCH}" https://github.com/Nitrux/maui-clip.git "$repo_root/maui-clip"
source_dir="$repo_root/maui-clip"

# -- Configure build.

# MauiKit software must be built with CMake and ECM; never use Meson.
build_dir="$repo_root/build"
cmake_dir="$build_dir/cmake"
stage_dir="$build_dir/package"
rm -rf "$cmake_dir" "$stage_dir"
mkdir -p "$build_dir"

cmake_args=(
    -DCMAKE_INSTALL_PREFIX=/usr
    -DCMAKE_BUILD_TYPE=Release
)
if [ "$(dpkg-architecture -qDEB_HOST_ARCH)" = "amd64" ]; then
    cmake_args+=("-DCMAKE_CXX_FLAGS=-march=x86-64-v3")
fi

# -- Compile Source

cmake -S "$source_dir" -B "$cmake_dir" "${cmake_args[@]}"
cmake --build "$cmake_dir" --parallel "$(nproc)"

# -- Install source to DESTDIR.

DESTDIR="$stage_dir" cmake --install "$cmake_dir"

# -- Create DEBIAN control file.

mkdir -p "$stage_dir/DEBIAN"
cat > "$stage_dir/DEBIAN/control" <<CONTROL
Package: clip
Version: ${PACKAGE_VERSION}
Section: utils
Priority: optional
Architecture: ${TARGET_ARCH}
Maintainer: uri_herrera@nxos.org
Provides: clip
Depends: qml6-module-qtquick-controls,qml6-module-qtquick-effects,qml6-module-qtquick-layouts,libqt6core6t64,libqt6network6,libqt6qml6,libqt6quick6,libc6,libmpv2,libqt6multimedia6,mauikit-filebrowsing (>= 4.0.4),mauikit (>= 4.0.4),qml6-module-qtcore,qml6-module-qtmultimedia
Description: clip
 clip
CONTROL

# -- Create .deb.

dpkg-deb --build --root-owner-group "$stage_dir" "$build_dir/clip_${PACKAGE_VERSION}_${TARGET_ARCH}.deb"
