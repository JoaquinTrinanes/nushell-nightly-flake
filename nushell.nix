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
  Security,
  Libsystem,
  AppKit,
  nghttp2,
  libgit2,
  doCheck ? true,
  withDefaultFeatures ? true,
  additionalFeatures ? (defaultFeatures: defaultFeatures),
  package ? "nu",
  pname ? "nushell",
  testers,
  nix-update-script,
}:
let
  inherit (import ./npins) nushell;
in
rustPlatform.buildRustPackage {
  inherit pname doCheck;
  version = nushell.revision;
  src = nushell;

  buildNoDefaultFeatures = !withDefaultFeatures;

  # Our source doesn't contain a .git folder from which to extract the hash,
  # so the build script is patched to fallback to our own hash instead of an empty string.
  # This is only relevant for showing the current commit when running the `version` command
  patchPhase = ''
    runHook prePatch

    substituteInPlace "crates/nu-cmd-lang/build.rs" --replace-fail "get_git_hash().unwrap_or_default();" "get_git_hash().unwrap_or(\"${nushell.revision}\".into());"
    runHook postPatch
  '';

  cargoLock = {
    lockFile = "${nushell}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };
  nativeBuildInputs =
    [ pkg-config ]
    ++ lib.optionals (withDefaultFeatures && stdenv.isLinux) [ python3 ]
    ++ lib.optionals stdenv.isDarwin [ rustPlatform.bindgenHook ];

  buildInputs =
    [
      openssl
      zstd
    ]
    ++ lib.optionals stdenv.isDarwin [
      zlib
      Libsystem
      Security
    ]
    ++ lib.optionals (withDefaultFeatures && stdenv.isLinux) [ xorg.libX11 ]
    ++ lib.optionals (withDefaultFeatures && stdenv.isDarwin) [
      AppKit
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

  cargoBuildFlags = [ "--package ${package}" ];

  buildFeatures = additionalFeatures [ ];

  meta = with lib; {
    description = "A modern shell written in Rust";
    homepage = "https://www.nushell.sh/";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = package;
  };
}
