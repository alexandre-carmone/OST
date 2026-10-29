---
title: NixOS
weight: 8
description: "Build, test and install OST on NixOS with the flake"
---

The repository ships a `flake.nix`. It builds the backend and the web UI
from the sources, and provides a NixOS module to run OST as a service.

## Build and test

Build the package (first build takes a while, it compiles everything):

```bash
nix build gitlab:ost/ostserver?host=gitlab.ostserver.fr
./result/bin/ostserver --help
```

From a clone of the repository, `nix build` does the same, and
`nix develop` opens a shell with every dependency for a plain
`cmake .. && make` build.

## Install as a service

Add the flake as an input of your system flake and enable the module:

```nix
{
  inputs.ostserver.url = "gitlab:ost/ostserver?host=gitlab.ostserver.fr";

  outputs = { nixpkgs, ostserver, ... }: {
    nixosConfigurations.observatory = nixpkgs.lib.nixosSystem {
      modules = [
        ostserver.nixosModules.default
        {
          services.ostserver = {
            enable = true;
            webUI.enable = true;   # web UI served by nginx on port 80
            openFirewall = true;
          };
        }
      ];
    };
  };
}
```

Then `nixos-rebuild switch` and open `http://<machine>/` in a browser.

## Options

| Option | Default | Role |
|---|---|---|
| `services.ostserver.enable` | `false` | Run the `ostserver` service |
| `services.ostserver.webUI.enable` | `false` | Serve the web UI with nginx on port 80 |
| `services.ostserver.openFirewall` | `false` | Open port 9624 (WebSocket) and 80 (web UI) |
| `services.ostserver.args` | `--indiserver=Y --loglevel=1 --grant=0` | Options passed to `ostserver`, see `ostserver --help` |
| `services.ostserver.package` | the flake's package | Use `pkgs.indi-full` drivers with `ostserver.packages.x86_64-linux.ostserver.override { indi = pkgs.indi-full; }` |

Data (database, logs, images) lives in `/var/lib/ostserver`, images are
served under `/ostmedia/`.

{{% notice style="note" title="Plate solving" %}}
`astrometry.net` index files are looked up in `/usr/share/astrometry`,
which does not exist on NixOS. Create that directory and copy your index
files there if you use the Navigator or Polar modules.
{{% /notice %}}
