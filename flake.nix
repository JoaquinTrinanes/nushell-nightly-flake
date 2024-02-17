{
  description = "Nushell nightly flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  nixConfig = {
    extra-substituters = [
      "https://nushell-nightly.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nushell-nightly.cachix.org-1:nLwXJzwwVmQ+fLKD6aH6rWDoTC73ry1ahMX9lU87nrc="
    ];
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

      flake.overlays.default = final: prev: let
        inherit (final.stdenv.hostPlatform) system;
        packages = inputs.self.packages.${system};
        inherit (inputs.nixpkgs) lib;
      in {
        inherit (packages) nushell nushellFull;
        nushellPlugins = let pluginPkgs = lib.filterAttrs (name: _: lib.hasPrefix "nu_plugin_" name) packages; in lib.mapAttrs' (name: value: lib.nameValuePair (lib.removePrefix "nu_plugin_" name) value) pluginPkgs;
      };

      perSystem = {
        pkgs,
        lib,
        ...
      }: {
        formatter = pkgs.alejandra;

        devShells.default = pkgs.mkShell {
          packages = builtins.attrValues {inherit (pkgs) npins;};
        };
        packages = let
          plugins = ["formats" "gstat" "inc" "query"];
          pluginPackageNames = map (p: "nu_plugin_${p}") plugins;
          nushell = pkgs.callPackage ./nushell.nix {
            doCheck = false;
            inherit (pkgs.darwin.apple_sdk_11_0) Libsystem;
            inherit (pkgs.darwin.apple_sdk_11_0.frameworks) AppKit Security;
          };
        in
          {
            inherit nushell;
            nushellFull = nushell.override {
              additionalFeatures = default: (default ++ ["extra" "dataframe"]);
            };
            default = nushell;
          }
          // (lib.genAttrs pluginPackageNames (
            package:
              nushell.overrideAttrs {
                inherit package;
                pname = package;
              }
          ));

        apps = let
          mkApp = app: {
            type = "app";
            program = pkgs.lib.getExe app;
          };
        in {
          update = let
            sources = import ./npins;
            inherit (sources) nushell;
          in
            mkApp (pkgs.writeShellApplication {
              name = "update";
              runtimeInputs = builtins.attrValues {inherit (pkgs) npins jq git;};
              text = ''
                BEFORE="${nushell.revision}"
                npins update
                AFTER="$(jq -j .pins.nushell.revision ./npins/sources.json)"


                if [ "$BEFORE" != "$AFTER" ]; then
                    git commit -a -m "Nushell: $BEFORE -> $AFTER"
                fi
              '';
            });
        };
      };
    };
}
