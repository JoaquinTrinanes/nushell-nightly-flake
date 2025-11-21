{
  description = "Nushell nightly flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-substituters = [ "https://nushell-nightly.cachix.org" ];
    extra-trusted-public-keys = [
      "nushell-nightly.cachix.org-1:nLwXJzwwVmQ+fLKD6aH6rWDoTC73ry1ahMX9lU87nrc="
    ];
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      flake.overlays.default =
        final: prev:
        let
          inherit (final.stdenv.hostPlatform) system;
          packages = inputs.self.packages.${system};
          inherit (inputs.nixpkgs) lib;
        in
        {
          inherit (packages) nushell;
          nushellPlugins =
            let
              pluginPkgs = lib.filterAttrs (name: _: lib.hasPrefix "nu_plugin_" name) packages;
            in
            prev.nushellPlugins
            // (lib.mapAttrs' (
              name: value: lib.nameValuePair (lib.removePrefix "nu_plugin_" name) value
            ) pluginPkgs);
        };

      perSystem =
        {
          pkgs,
          system,
          lib,
          ...
        }:
        let
          inherit (import ./npins) nushell;
          toolchain = pkgs.rust-bin.fromRustupToolchainFile "${nushell}/rust-toolchain.toml";
        in
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.rust-overlay.overlays.default ];
          };
          formatter = pkgs.nixfmt;

          devShells.default = pkgs.mkShell { packages = builtins.attrValues { inherit (pkgs) npins; }; };
          packages =
            let
              plugins = [
                "formats"
                "gstat"
                "inc"
                "query"
                "polars"
              ];
              pluginPackageNames = map (p: "nu_plugin_${p}") plugins;
              nushell = pkgs.callPackage ./nushell.nix {
                doCheck = false;
                rustPlatform = pkgs.makeRustPlatform {
                  cargo = toolchain;
                  rustc = toolchain;
                };
              };
              mkPlugin =
                name:
                nushell.overrideAttrs (
                  _final: _prev: {
                    pname = name;
                    meta.mainProgram = name;
                    cargoBuildFlags = [ "--package ${name}" ];
                  }
                );
            in
            {
              inherit nushell;
              default = nushell;
              tree-sitter-nu =
                let
                  inherit (import ./npins) tree-sitter-nu;
                in
                pkgs.tree-sitter.buildGrammar {
                  language = "nu";
                  version = tree-sitter-nu.revision;
                  src = tree-sitter-nu;
                };
            }
            // (lib.genAttrs (lib.remove "nu_plugin_query" pluginPackageNames) mkPlugin)
            // {
              nu_plugin_query = (mkPlugin "nu_plugin_query").overrideAttrs (
                _final: prev: {
                  buildInputs =
                    prev.buildInputs ++ [ pkgs.openssl ] ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.curl ];
                }
              );
              nu_plugin_gstat = (mkPlugin "nu_plugin_gstat").overrideAttrs (
                _final: prev: {
                  buildInputs = prev.buildInputs ++ [ pkgs.openssl ];
                }
              );
            };

          apps =
            let
              mkApp = app: {
                type = "app";
                program = pkgs.lib.getExe app;
              };
            in
            {
              update =
                let
                  sources = import ./npins;
                  inherit (sources) nushell;
                in
                mkApp (
                  pkgs.writeShellApplication {
                    name = "update";
                    runtimeInputs = builtins.attrValues { inherit (pkgs) npins jq git; };
                    text = ''
                      BEFORE="${nushell.revision}"
                      npins update
                      AFTER="$(jq -j .pins.nushell.revision ./npins/sources.json)"


                      if [ "$BEFORE" != "$AFTER" ]; then
                          git commit -a -m "Nushell: $BEFORE -> $AFTER"
                      fi
                    '';
                  }
                );
            };
        };
    };
}
