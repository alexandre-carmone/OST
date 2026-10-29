---
title: NixOS
weight: 8
description: "Compilar, probar e instalar OST en NixOS con el flake"
---

El repositorio incluye un `flake.nix`. Compila el servidor y la interfaz
web desde las fuentes y proporciona un módulo NixOS para ejecutar OST
como servicio.

## Compilar y probar

Compilar el paquete (la primera vez tarda, compila todo):

```bash
nix build gitlab:ost/ostserver?host=gitlab.ostserver.fr
./result/bin/ostserver --help
```

Desde un clon del repositorio, `nix build` hace lo mismo, y
`nix develop` abre un shell con todas las dependencias para un simple
`cmake .. && make`.

## Instalar como servicio

Añadir el flake a las entradas del flake del sistema y activar el módulo:

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
            webUI.enable = true;   # interfaz web servida por nginx en el puerto 80
            openFirewall = true;
          };
        }
      ];
    };
  };
}
```

Luego `nixos-rebuild switch` y abrir `http://<máquina>/` en un navegador.

## Options

| Opción | Por defecto | Función |
|---|---|---|
| `services.ostserver.enable` | `false` | Ejecuta el servicio `ostserver` |
| `services.ostserver.webUI.enable` | `false` | Sirve la interfaz web con nginx en el puerto 80 |
| `services.ostserver.openFirewall` | `false` | Abre los puertos 9624 (WebSocket) y 80 (interfaz web) |
| `services.ostserver.args` | `--indiserver=Y --loglevel=1 --grant=0` | Opciones pasadas a `ostserver`, ver `ostserver --help` |
| `services.ostserver.package` | paquete del flake | Para los controladores de `pkgs.indi-full`: `ostserver.packages.x86_64-linux.ostserver.override { indi = pkgs.indi-full; }` |

Los datos (base de datos, registros, imágenes) están en `/var/lib/ostserver`,
las imágenes se sirven bajo `/ostmedia/`.

{{% notice style="note" title="Resolución astrométrica" %}}
Los índices de `astrometry.net` se buscan en `/usr/share/astrometry`,
que no existe en NixOS. Cree esa carpeta y copie allí sus archivos de
índice si usa los módulos Navigator o Polar.
{{% /notice %}}
