{
  stdenv,
  lib,
  fetchFromGitHub,
  rustPlatform,
  openssl,
  zlib,
  zstd,
  pkg-config,
  python3,
  xorg,
  Security,
  Libsystem,
  AppKit,
  nghttp2,
  libgit2,
  doCheck ? true,
  buildNoDefaultFeatures ? false,
  buildFeatures ? (defaultFeatures: defaultFeatures),
  testers,
  nushell,
  nix-update-script,
  fetchgit,
  fetchurl,
  dockerTools,
}: let
  source = (import ./_sources/generated.nix {inherit fetchgit fetchurl fetchFromGitHub dockerTools;}).nushell;
in
  rustPlatform.buildRustPackage {
    inherit buildNoDefaultFeatures doCheck;
    inherit (source) pname version src;

    cargoLock = {
      inherit (source.cargoLock."Cargo.lock") lockFile outputHashes;
    };
    nativeBuildInputs =
      [pkg-config]
      ++ lib.optionals (!buildNoDefaultFeatures && stdenv.isLinux) [python3]
      ++ lib.optionals stdenv.isDarwin [rustPlatform.bindgenHook];

    buildInputs =
      [openssl zstd]
      ++ lib.optionals stdenv.isDarwin [
        zlib
        Libsystem
        Security
      ]
      ++ lib.optionals (!buildNoDefaultFeatures && stdenv.isLinux) [xorg.libX11]
      ++ lib.optionals (!buildNoDefaultFeatures && stdenv.isDarwin) [AppKit nghttp2 libgit2];

    checkPhase = ''
      runHook preCheck
      echo "Running cargo test"
      HOME=$(mktemp -d) cargo test
      runHook postCheck
    '';

    passthru = {
      shellPath = "/bin/nu";
      tests.version = testers.testVersion {
        package = nushell;
      };
      updateScript = nix-update-script {};
    };

    buildFeatures = buildFeatures [];

    meta = with lib; {
      description = "A modern shell written in Rust";
      homepage = "https://www.nushell.sh/";
      license = licenses.mit;
      maintainers = [];
      mainProgram = "nu";
    };
  }
