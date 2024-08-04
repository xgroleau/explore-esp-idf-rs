{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    esp-dev = {
      url = "github:hsel-netsys/nixpkgs-esp-dev-rust/rust";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      esp-dev,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ esp-dev.overlays.default ];
        };

        espIdf = pkgs.esp-idf-esp32.override {
          toolsToInclude = [
            "xtensa-esp32-elf"
            "xtensa-esp-elf-gdb"
            "esp32ulp-elf"
          ];
        };
      in
      {
        devShells.default =
          with pkgs;
          mkShell {
            nativeBuildInputs = [ ];
            buildInputs =
              [
                espflash
                espup
                pkg-config

                # LLVM
                llvm-xtensa
                llvm-xtensa-lib

                # Rust
                rust-xtensa

                # Rust development tools for ESP
                rust-ldproxy
                rust-cargo-espflash

                # We don't really care for IDF_PATH, just want the xtensa compiler and stuff
                espIdf
              ]
              ++ lib.optionals stdenv.isDarwin [
                darwin.apple_sdk.frameworks.CoreFoundation
                darwin.apple_sdk.frameworks.Foundation
                libiconv
              ];

            shellHook = ''
              unset CC
              unset CXX
              unset AR

              # Let esp-idf-sys clone the repo themselves
              unset IDF_PATH
              unset IDF_TOOLS_PATH
              unset IDF_PYTHON_CHECK_CONSTRAINTS
              unset IDF_PYTHON_ENV_PATH
            '';
          };
      }
    );
}
