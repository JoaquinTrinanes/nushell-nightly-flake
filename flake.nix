{
  description = "Nushell nightly flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # nushell-src.url = "github:nushell/nushell";
    # nushell-src.flake = false;
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux"];
    forEachSystem = nixpkgs.lib.genAttrs supportedSystems;
  in {
    packages = forEachSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      commonArgs = {
        doCheck = false;
        inherit (pkgs.darwin.apple_sdk.frameworks) Libsystem Security AppKit;
      };
    in {
      nushellFull = pkgs.callPackage ./nushell.nix ({
          additionalFeatures = p: (p ++ ["extra" "dataframe"]);
        }
        // commonArgs);
      nushell = pkgs.callPackage ./nushell.nix commonArgs;
      default = self.packages.${system}.nushell;
    });
  };
}
