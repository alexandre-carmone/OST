---
title: NixOS
weight: 8
description: "Compiler, tester et installer OST sur NixOS avec le flake"
---

Le dépôt fournit un `flake.nix`. Il compile le serveur et l'interface web
depuis les sources, et fournit un module NixOS pour lancer OST comme service.

## Compiler et tester

Compiler le paquet (la première fois est longue, tout est compilé) :

```bash
nix build gitlab:ost/ostserver?host=gitlab.ostserver.fr
./result/bin/ostserver --help
```

Depuis un clone du dépôt, `nix build` fait la même chose, et
`nix develop` ouvre un shell avec toutes les dépendances pour un
simple `cmake .. && make`.

## Installer comme service

Ajouter le flake aux entrées du flake de votre système et activer le module :

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
            webUI.enable = true;   # interface web servie par nginx sur le port 80
            openFirewall = true;
          };
        }
      ];
    };
  };
}
```

Puis `nixos-rebuild switch` et ouvrir `http://<machine>/` dans un navigateur.

## Options

| Option | Défaut | Rôle |
|---|---|---|
| `services.ostserver.enable` | `false` | Lance le service `ostserver` |
| `services.ostserver.webUI.enable` | `false` | Sert l'interface web avec nginx sur le port 80 |
| `services.ostserver.openFirewall` | `false` | Ouvre les ports 9624 (WebSocket) et 80 (interface web) |
| `services.ostserver.args` | `--indiserver=Y --loglevel=1 --grant=0` | Options passées à `ostserver`, voir `ostserver --help` |
| `services.ostserver.package` | le paquet du flake | Pour les pilotes de `pkgs.indi-full` : `ostserver.packages.x86_64-linux.ostserver.override { indi = pkgs.indi-full; }` |

Les données (base, journaux, images) sont dans `/var/lib/ostserver`, les
images sont servies sous `/ostmedia/`.

{{% notice style="note" title="Résolution astrométrique" %}}
Les index `astrometry.net` sont cherchés dans `/usr/share/astrometry`,
qui n'existe pas sur NixOS. Créez ce dossier et copiez-y vos fichiers
d'index si vous utilisez les modules Navigator ou Polar.
{{% /notice %}}
