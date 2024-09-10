(import (
  let
    pin = (builtins.fromJSON (builtins.readFile ./npins/sources.json)).pins.flake-compat;
  in
  fetchTarball {
    inherit (pin) url;
    sha256 = pin.hash;
  }
) { src = ./.; }).defaultNix
