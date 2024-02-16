{
  description = "Nushell nightly flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
  };

  nixConfig = {
    extra-substituters = [
      "https://nushell-nightly.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nushell-nightly.cachix.org-1:nLwXJzwwVmQ+fLKD6aH6rWDoTC73ry1ahMX9lU87nrc="
    ];
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forEachSystem = f:
      (nixpkgs.lib.genAttrs supportedSystems)
      (system: f nixpkgs.legacyPackages.${system});
  in {
    devShells = forEachSystem (pkgs: {
      default = pkgs.mkShell {
        packages = builtins.attrValues {inherit (pkgs) npins;};
      };
    });
    formatter = forEachSystem (pkgs: pkgs.alejandra);
    packages = forEachSystem (pkgs: let
      commonArgs = {
        doCheck = false;
        inherit (pkgs.darwin.apple_sdk_11_0) Libsystem;
        inherit (pkgs.darwin.apple_sdk_11_0.frameworks) AppKit Security;
      };
    in {
      nushellFull = pkgs.callPackage ./nushell.nix ({
          additionalFeatures = p: (p ++ ["extra" "dataframe"]);
        }
        // commonArgs);
      nushell = pkgs.callPackage ./nushell.nix commonArgs;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.nushell;
    });

    overlays.default = final: prev: let
      inherit (prev.stdenv.hostPlatform) system;
    in {
      inherit (self.packages.${system}) nushell nushellFull;
    };
  };
}
