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
  curlMinimal,
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
    zstd
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ zlib ]
  ++ lib.optionals (withDefaultFeatures && stdenv.hostPlatform.isLinux) [ xorg.libX11 ]
  ++ lib.optionals (withDefaultFeatures && stdenv.hostPlatform.isDarwin) [
    nghttp2
    libgit2
  ];

  checkInputs =
    lib.optionals stdenv.hostPlatform.isDarwin [ curlMinimal ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ openssl ];

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
    description = "Modern shell written in Rust";
    homepage = "https://www.nushell.sh/";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "nu";
  };
}
