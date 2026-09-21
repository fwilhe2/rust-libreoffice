# SPDX-FileCopyrightText: 2025 Florian Wilhelm
#
# SPDX-License-Identifier: MIT

FROM docker.io/rust:1-trixie
ENV DEBIAN_FRONTEND=noninteractive

COPY debian-backports.sources /etc/apt/sources.list.d/debian-backports.sources

# Two installs on purpose: `-t trixie-backports` makes backports the preferred release for
# *every* package in that command, and only LibreOffice wants that. The rest is what an
# agent (or a person) working on grind in a sandbox VM reaches for, so nobody has to
# apt-get inside a fresh VM:
#   - general:  git, search/inspect utilities, zip (ODF packages are zips), python3, nodejs
#   - GTK shells (ui_sheet_gtk, ui_text_gtk): GTK4 + libadwaita dev files, plus xvfb, mesa,
#     fonts and an icon theme so `--render-to` and the widget tests run headless
#   - screenshots: xterm, imagemagick
#   - win32 shell: clang/lld/llvm for cargo-xwin, wine to run the result
#   - wasm: binaryen (wasm-opt)
#   - packaging/artifacts: rpm tooling, genisoimage
RUN apt-get -qq update \
    && apt-get install --no-install-recommends -yqq \
        ca-certificates curl git jq less libxml2-utils openssh-client procps \
        python3 python3-venv pipx ripgrep unzip zip nodejs npm \
        libgtk-4-dev libadwaita-1-dev libgl1-mesa-dri xvfb xauth dbus-x11 \
        adwaita-icon-theme fonts-dejavu-core fonts-liberation2 \
        xterm imagemagick genisoimage \
        clang lld llvm binaryen \
    && if [ "$(dpkg --print-architecture)" = amd64 ]; then \
        apt-get install --no-install-recommends -yqq wine wine64; \
    fi \
    && apt-get install -t trixie-backports --no-install-recommends -yqq \
        libreoffice-calc libreoffice-writer libreoffice-l10n-de jing \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# The official rust image ships the minimal profile: no rustfmt, no clippy. wasm32 is what
# grind's web shell builds for, the msvc target is what cargo-xwin links.
RUN rustup component add rustfmt clippy \
    && rustup target add wasm32-unknown-unknown x86_64-pc-windows-msvc

# Cargo subcommands grind's workflows and scripts use. ui_web/build.sh refuses a
# wasm-bindgen CLI that differs from the version in grind's Cargo.lock, so it is pinned:
# bump the ARG when grind's lockfile moves (build.sh prints the fix if they disagree).
# Built in a throwaway target dir and registry so none of it stays in the layer.
ARG WASM_BINDGEN_VERSION=0.2.127
RUN CARGO_TARGET_DIR=/tmp/cargo-install-target cargo install --locked \
        cargo-deb cargo-generate-rpm cargo-bloat twiggy cargo-xwin \
    && CARGO_TARGET_DIR=/tmp/cargo-install-target cargo install --locked \
        wasm-bindgen-cli --version "${WASM_BINDGEN_VERSION}" \
    && rm -rf /tmp/cargo-install-target "${CARGO_HOME}/registry" "${CARGO_HOME}/git"

# fsfe/reuse from PyPI rather than Debian's package, which lags by years. Unpinned, so the
# nightly rebuild (see ci.yaml) keeps it on the latest release.
ENV PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin
RUN pipx install reuse && reuse --version

# Claude Code is deliberately *not* installed here: it is proprietary software that this
# public image has no right to redistribute. Whoever runs the image installs it themselves
# (grind's scripts/claude-vm.sh does so on first `up`); its installer uses ~/.local/bin.
ENV PATH="/root/.local/bin:${PATH}"

# Bind-mounted checkouts are owned by the host user, not the container's root, which git
# calls dubious. Scoped to the conventional mount point rather than '*'.
RUN git config --system --add safe.directory /work

# Debian only ships the versioned llvm-windres-NN; grind's ui_win32/build.rs (embed_resource)
# looks for the plain name.
RUN ln -s "$(ls /usr/bin/llvm-windres-* | head -n1)" /usr/local/bin/llvm-windres

WORKDIR /work
