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
          mkShellNoCC {
            nativeBuildInputs = [
              espflash
              espup
              ldproxy

              # We don't really care for IDF_PATH, just want the xtensa compiler and stuff
              esp-idf-esp32
            ];
            buildInputs = [ libiconv ];

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
