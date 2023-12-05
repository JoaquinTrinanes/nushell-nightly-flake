{
  description = "Nushell nightly flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux" "x86_64-darwin"];
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
          buildFeatures = p: (p ++ ["extra" "dataframe"]);
        }
        // commonArgs);
      nushell = pkgs.callPackage ./nushell.nix commonArgs;
      default = self.packages.${system}.nushell;
    });
  };
}
