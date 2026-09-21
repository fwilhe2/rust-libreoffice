# Container Image with Rust and LibreOffice

This is used for tests of [grind](https://github.com/fwilhe2/grind)


## Contents

- Rust (stable) with `rustfmt`, `clippy` and the `wasm32-unknown-unknown` and
  `x86_64-pc-windows-msvc` targets
- LibreOffice Calc and Writer (from Debian backports) and `jing`
- [`reuse`](https://github.com/fsfe/reuse-tool), latest release from PyPI (rebuilt nightly)
- GTK 4 and libadwaita development files, `xvfb`, Mesa, fonts (for the GTK shells, headless)
- `cargo-deb`, `cargo-generate-rpm`, `cargo-bloat`, `twiggy`, `cargo-xwin`, and
  `wasm-bindgen-cli` (pinned to the version in grind's `Cargo.lock`, see `WASM_BINDGEN_VERSION`
  in the `Containerfile`), `wasm-opt`
- clang, lld, llvm (`llvm-windres` included) and Wine (amd64 only), for the Windows shell
- Node.js and npm, ImageMagick, xterm, `genisoimage`
- `git`, `curl`, `jq`, `ripgrep`, `xmllint`, `zip`/`unzip`, `python3`

The image is meant to work as a sandbox VM base (e.g. with smolvm): a checkout mounted at
`/work` is trusted by git, and `/work` is the default working directory.

Claude Code is **not** included, because it is proprietary and cannot be redistributed in a
public image. Install it inside the sandbox instead (`curl -fsSL https://claude.ai/install.sh | bash`).
