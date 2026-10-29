{
  description = "OST - Observatoire Sans Tête, headless astrophotography automation";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        ostserver = pkgs.callPackage ./nix/package.nix {
          src = self;
          version = self.shortRev or self.dirtyShortRev or "dirty";
        };
        default = ostserver;
      });

      # `nix develop` gives a shell with every build dependency, for a
      # plain `cmake .. && make` in a build/ directory.
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          inputsFrom = [ self.packages.${pkgs.system}.ostserver ];
        };
      });
    };
}
