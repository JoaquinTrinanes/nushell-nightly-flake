{
  stdenv,
  lib,
  rustPlatform,
  openssl,
  zlib,
  zstd,
  pkg-config,
  python3,
  xorg,
  nghttp2,
  libgit2,
  doCheck ? true,
  withDefaultFeatures ? true,
  additionalFeatures ? (defaultFeatures: defaultFeatures),
  testers,
  nix-update-script,
  apple-sdk_11,
}:
let
  inherit (import ./npins) nushell;
in
rustPlatform.buildRustPackage {
  pname = "nushell";
  inherit doCheck;
  version =
    let
      cargo = builtins.fromTOML (builtins.readFile "${nushell}/Cargo.toml");
    in
    cargo.package.version;
  src = nushell;

  buildNoDefaultFeatures = !withDefaultFeatures;

  env.NU_COMMIT_HASH = nushell.revision;

  cargoLock = {
    lockFile = "${nushell}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };
  nativeBuildInputs = [
    pkg-config
  ]
  ++ lib.optionals (withDefaultFeatures && stdenv.isLinux) [ python3 ]
  ++ lib.optionals stdenv.isDarwin [ rustPlatform.bindgenHook ];

  buildInputs = [
    openssl
    zstd
  ]
  ++ lib.optionals stdenv.isDarwin [
    apple-sdk_11
    zlib
  ]
  ++ lib.optionals (withDefaultFeatures && stdenv.isLinux) [ xorg.libX11 ]
  ++ lib.optionals (withDefaultFeatures && stdenv.isDarwin) [
    nghttp2
    libgit2
  ];

  checkPhase = ''
    runHook preCheck
    echo "Running cargo test"
    HOME=$(mktemp -d) cargo test
    runHook postCheck
  '';

  passthru = {
    shellPath = "/bin/nu";
    tests.version = testers.testVersion { package = nushell; };
    updateScript = nix-update-script { };
  };

  buildFeatures = additionalFeatures [ ];

  meta = with lib; {
    description = "A modern shell written in Rust";
    homepage = "https://www.nushell.sh/";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "nu";
  };
}
