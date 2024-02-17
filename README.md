# 🐘 [Nushell](https://github.com/nushell/nushell) Nightly Flake

## Featuring

- Handy overlay
- Hourly builds to live on the bleeding edge
- It's own binary cache
- Optional `dataframe` and `extra` features support (cached of course)
- Official nushell plugins:
  - nu_plugin_custom_values
  - nu_plugin_formats
  - nu_plugin_gstat
  - nu_plugin_inc
  - nu_plugin_python
  - nu_plugin_query

## Getting started

### Binary cache

To avoid long build times and a toasty computer, a binary cache is provided. To enable it, follow the instructions on the [`nushell-nightly` binary cache](https://app.cachix.org/cache/nushell-nightly).

Alternatively, you can enable the cache manually.

- If using NixOS, set the following values in your config:

  ```nix
  nix.settings.substituters = ["https://nushell-nightly.cachix.org"];
  nix.settings.trusted-public-keys = ["nushell-nightly.cachix.org-1:nLwXJzwwVmQ+fLKD6aH6rWDoTC73ry1ahMX9lU87nrc="];
  ```

- If using standalone Nix, edit either `/etc/nix/nix.conf` or `~/.config/nix/nix.conf`

  ```conf
  substituters = https://nushell-nightly.cachix.org
  trusted-public-keys = nushell-nightly.cachix.org-1:nLwXJzwwVmQ+fLKD6aH6rWDoTC73ry1ahMX9lU87nrc=
  ```

  Note that if you enable the cache in your user config it won't take affect unless the user is in the `trusted-users` list.

### Using flakes

#### Using the packages

```nix
environment.systemPackages = [
    # You can access nushell, nushellFull, nu_plugin_* and default (alias to nushell)
    inputs.nushell-nightly.packages.${pkgs.stdenv.hostPlatform.system}.default;
];
```

#### Using the overlay

The flake exports an overlay that takes care of overriding the `nushell`, `nushellPlugins`, `nushellFull` (`extra` and `dataframe` features enabled) packages.

```nix
import nixpkgs {
    overlays = [inputs.nushell-nightly-flake.overlays.default];
    ...
};
```

### Nix without flakes using `flake-compat`

```nix
environment.systemPackages = [
    (import (fetchTarball "https://github.com/JoaquinTrinanes/nushell-nightly-flake/archive/main.tar.gz")).default
    # or, for nushellFull
    (import (fetchTarball "https://github.com/JoaquinTrinanes/nushell-nightly-flake/archive/main.tar.gz")).packages.${pkgs.stdenv.hostPlatform.system}.nushellFull
];
```
