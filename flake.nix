{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # flake-parts = {
    #   url = "github:hercules-ci/flake-parts";
    #   inputs.nixpkgs-lib.follows = "nixpkgs";
    # };
    hercules-ci-effects = {
      url = "github:hercules-ci/hercules-ci-effects";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    flake-utils.url = "github:numtide/flake-utils";
    nushell = {
      url = "github:nushell/nushell";
      flake = false;
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    crane,
    nushell,
    rust-overlay,
    flake-utils,
    flake-compat,
  }: let
    # supportedSystems = with flake-utils.lib.system; [
    #   # flake-utils.lib.system.x86_64-linux
    #   x86_64-linux
    #   aarch64-linux
    #   aarch64-darwin
    #   x86_64-darwin
    #   x86_64-windows
    #   # aarch64-windows
    #   # x86_64-unknown-linux-gnu
    #   # x86_64-unknown-linux-musl
    #   # aarch64-unknown-linux-gnu
    #   # armv7-unknown-linux-gnueabihf
    #   # riscv64gc-unknown-linux-gnu
    # ];
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
      "x86_64-windows"
      "aarch64-pc-windows-msvc"
      "x86_64-unknown-linux-gnu"
      "x86_64-unknown-linux-musl"
      "aarch64-unknown-linux-gnu"
      "armv7-unknown-linux-gnueabihf"
      "riscv64gc-unknown-linux-gnu"
    ];
    forAllSystems = flake-utils.lib.eachSystem supportedSystems;
    # forAllSystems = flake-utils.lib.eachDefaultSystem;
  in
    forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [(import rust-overlay)];
      };
      rust-toolchain = pkgs.rust-bin.fromRustupToolchainFile "${nushell.outPath}/rust-toolchain.toml";
      craneLib = (crane.mkLib pkgs).overrideToolchain rust-toolchain;
      nushell-crate = pkgs.callPackage ./nushell.nix {
        src = nushell.outPath;
        doCheck = false;
        inherit craneLib;
        features = ["extra" "dataframe"];
      };
    in {
      checks = {inherit nushell-crate;};
      packages.default = nushell-crate;

      apps.default = flake-utils.lib.mkApp {
        drv = nushell-crate;
      };

      devShells.default = craneLib.devShell {
        # Inherit inputs from checks.
        checks = self.checks.${system};

        # Additional dev-shell environment variables can be set directly
        # MY_CUSTOM_DEVELOPMENT_VAR = "something else";

        # Extra inputs can be added here; cargo and rustc are provided by default.
        packages = [
          # pkgs.ripgrep
        ];
      };
    });

  hercules-ci.flake-update = {
    enable = true;
    createPullRequest = false;
    updateBranch = "main";
    # Update everynight at midnight
    when = {
      hour = [0];
      minute = 0;
    };
  };
}
