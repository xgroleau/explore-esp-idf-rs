{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    esp-dev = {
      url = "github:mirrexagon/nixpkgs-esp-dev/master";
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

        espIdf32 = pkgs.esp-idf-esp32.override { };
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
                ldproxy
                pkg-config

                # We don't really care for IDF_PATH, just want the xtensa compiler and stuff
                esp-idf-esp32
              ]
              ++ lib.optionals stdenv.isDarwin [
                darwin.CF
                darwin.apple_sdk.frameworks.AppKit
                darwin.apple_sdk.frameworks.CoreServices
                darwin.apple_sdk.frameworks.CoreFoundation
                darwin.apple_sdk.frameworks.Foundation
                darwin.apple_sdk.frameworks.Security
                darwin.apple_sdk.frameworks.Foundation
                libiconv
              ];

            LD_LIBRARY_PATH = lib.makeLibraryPath [ libiconv ];
            LIBRARY_PATH = lib.makeLibraryPath [
              libiconv
              darwin.apple_sdk.frameworks.AppKit
              darwin.apple_sdk.frameworks.CoreFoundation
              darwin.apple_sdk.frameworks.Foundation
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
