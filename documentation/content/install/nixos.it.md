---
title: NixOS
weight: 8
description: "Compilare, testare e installare OST su NixOS con il flake"
---

Il repository include un `flake.nix`. Compila il server e l'interfaccia
web dai sorgenti e fornisce un modulo NixOS per eseguire OST come servizio.

## Compilare e testare

Compilare il pacchetto (la prima volta è lunga, compila tutto):

```bash
nix build gitlab:ost/ostserver?host=gitlab.ostserver.fr
./result/bin/ostserver --help
```

Da un clone del repository, `nix build` fa lo stesso, e
`nix develop` apre una shell con tutte le dipendenze per un semplice
`cmake .. && make`.

## Installare come servizio

Aggiungere il flake agli input del flake di sistema e abilitare il modulo:

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
            webUI.enable = true;   # interfaccia web servita da nginx sulla porta 80
            openFirewall = true;
          };
        }
      ];
    };
  };
}
```

Poi `nixos-rebuild switch` e aprire `http://<macchina>/` in un browser.

## Options

| Opzione | Default | Ruolo |
|---|---|---|
| `services.ostserver.enable` | `false` | Avvia il servizio `ostserver` |
| `services.ostserver.webUI.enable` | `false` | Serve l'interfaccia web con nginx sulla porta 80 |
| `services.ostserver.openFirewall` | `false` | Apre le porte 9624 (WebSocket) e 80 (interfaccia web) |
| `services.ostserver.args` | `--indiserver=Y --loglevel=1 --grant=0` | Opzioni passate a `ostserver`, vedere `ostserver --help` |
| `services.ostserver.package` | pacchetto del flake | Per i driver di `pkgs.indi-full`: `ostserver.packages.x86_64-linux.ostserver.override { indi = pkgs.indi-full; }` |

I dati (database, log, immagini) sono in `/var/lib/ostserver`, le
immagini sono servite sotto `/ostmedia/`.

{{% notice style="note" title="Plate solving" %}}
I file indice di `astrometry.net` vengono cercati in `/usr/share/astrometry`,
che non esiste su NixOS. Create quella cartella e copiatevi i vostri file
indice se usate i moduli Navigator o Polar.
{{% /notice %}}
