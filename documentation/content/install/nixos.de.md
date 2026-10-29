---
title: NixOS
weight: 8
description: "OST auf NixOS mit dem Flake bauen, testen und installieren"
---

Das Repository enthält eine `flake.nix`. Sie baut den Server und die
Weboberfläche aus den Quellen und liefert ein NixOS-Modul, um OST als
Dienst zu betreiben.

## Bauen und testen

Das Paket bauen (der erste Build dauert, es wird alles kompiliert):

```bash
nix build gitlab:ost/ostserver?host=gitlab.ostserver.fr
./result/bin/ostserver --help
```

In einem Klon des Repositories macht `nix build` dasselbe, und
`nix develop` öffnet eine Shell mit allen Abhängigkeiten für ein
einfaches `cmake .. && make`.

## Als Dienst installieren

Das Flake als Input des System-Flakes eintragen und das Modul aktivieren:

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
            webUI.enable = true;   # Weboberfläche von nginx auf Port 80 ausgeliefert
            openFirewall = true;
          };
        }
      ];
    };
  };
}
```

Dann `nixos-rebuild switch` und `http://<rechner>/` im Browser öffnen.

## Options

| Option | Standard | Zweck |
|---|---|---|
| `services.ostserver.enable` | `false` | Startet den Dienst `ostserver` |
| `services.ostserver.webUI.enable` | `false` | Liefert die Weboberfläche mit nginx auf Port 80 aus |
| `services.ostserver.openFirewall` | `false` | Öffnet Port 9624 (WebSocket) und 80 (Weboberfläche) |
| `services.ostserver.args` | `--indiserver=Y --loglevel=1 --grant=0` | Optionen für `ostserver`, siehe `ostserver --help` |
| `services.ostserver.package` | Paket des Flakes | Für die Treiber aus `pkgs.indi-full`: `ostserver.packages.x86_64-linux.ostserver.override { indi = pkgs.indi-full; }` |

Daten (Datenbank, Logs, Bilder) liegen in `/var/lib/ostserver`, Bilder
werden unter `/ostmedia/` ausgeliefert.

{{% notice style="note" title="Plate Solving" %}}
Die `astrometry.net`-Indexdateien werden in `/usr/share/astrometry`
gesucht, das es auf NixOS nicht gibt. Legen Sie dieses Verzeichnis an und
kopieren Sie Ihre Indexdateien dorthin, wenn Sie die Module Navigator
oder Polar nutzen.
{{% /notice %}}
