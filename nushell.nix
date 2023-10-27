{
  openssl,
  libiconv,
  lib,
  pkg-config,
  stdenv,
  craneLib,
  src,
  features ? [],
  defaultFeatures ? true,
  doCheck ? true,
}:
craneLib.buildPackage {
  src = lib.cleanSourceWith {
    src = craneLib.path src;
    filter = path: type: (craneLib.filterCargoSources path type) || ((builtins.match ".*\.nu" path) != null);
  };

  strictDeps = true;

  inherit doCheck;

  extraCargoArgs = builtins.toString (lib.optionals (!defaultFeatures) ["--no-default-features"] ++ builtins.map (f: "--feature ${f}") features);

  # Build-time tools which are target agnostic. build = host = target = your-machine.
  # Emulators should essentially also go `nativeBuildInputs`. But with some packaging issue,
  # currently it would cause some rebuild.
  # We put them here just for a workaround.
  # See: https://github.com/NixOS/nixpkgs/pull/146583
  depsBuildBuild = [
    # qemu
  ];

  # Dependencies which need to be build for the current platform
  # on which we are doing the cross compilation. In this case,
  # pkg-config needs to run on the build platform so that the build
  # script can find the location of openssl. Note that we don't
  # need to specify the rustToolchain here since it was already
  # overridden above.
  nativeBuildInputs =
    [
      pkg-config
    ]
    ++ lib.optionals stdenv.buildPlatform.isDarwin [
      libiconv
    ];

  # Dependencies which need to be built for the platform on which
  # the binary will run. In this case, we need to compile openssl
  # so that it can be linked with our executable.
  buildInputs = [
    # Add additional build inputs here
    openssl
  ];

  # Tell cargo about the linker and an optional emulater. So they can be used in `cargo build`
  # and `cargo run`.
  # Environment variables are in format `CARGO_TARGET_<UPPERCASE_UNDERSCORE_RUST_TRIPLE>_LINKER`.
  # They are also be set in `.cargo/config.toml` instead.
  # See: https://doc.rust-lang.org/cargo/reference/config.html#target
  # CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "${stdenv.cc.targetPrefix}cc";
  # CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_RUNNER = "qemu-aarch64";

  # Tell cargo which target we want to build (so it doesn't default to the build system).
  # We can either set a cargo flag explicitly with a flag or with an environment variable.
  # cargoExtraArgs = "--target aarch64-unknown-linux-gnu";
  # CARGO_BUILD_TARGET = "aarch64-unknown-linux-gnu";

  # This environment variable may be necessary if any of your dependencies use a
  # build-script which invokes the `cc` crate to build some other code. The `cc` crate
  # should automatically pick up on our target-specific linker above, but this may be
  # necessary if the build script needs to compile and run some extra code on the build
  # system.
  HOST_CC = "${stdenv.cc.nativePrefix}cc";
}
