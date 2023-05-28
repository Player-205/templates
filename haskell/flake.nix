# SPDX-FileCopyrightText: 2021 Serokell <https://serokell.io/>
#
# SPDX-License-Identifier: CC0-1.0

{
  description = "My haskell application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        haskellPackages = pkgs.haskellPackages;

        cabal-install-wrapper = pkgs.writeScriptBin "cabal"
          ''
          #!${pkgs.bash}
          ${pkgs.haskellPackages.cabal-fmt} -i *.cabal
          ${pkgs.cabal-install} $@
          '';

        hls-wrapper = pkgs.writeScriptBin "haskell-language-server"
          ''
          #!${pkgs.bash}/bin/bash
          PATH=${pkgs.cabal-install}/bin:$PATH ${haskellPackages.haskell-language-server}/bin/haskell-language-server $@
          '';

        jailbreakUnbreak = pkg:
          pkgs.haskell.lib.doJailbreak (pkg.overrideAttrs (_: { meta = { }; }));

        packageName = "template";
      in {
        packages.${packageName} =
          haskellPackages.callCabal2nix packageName self rec {
            # Dependency overrides go here
          };

        packages.default = self.packages.${system}.${packageName};
        defaultPackage = self.packages.${system}.default;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            hls-wrapper
            ghcid
            cabal-install-wrapper
            haskellPackages.cabal-fmt
          ];
          inputsFrom = map (__getAttr "env") (__attrValues self.packages.${system});
        };
        devShell = self.devShells.${system}.default;
      });
}
