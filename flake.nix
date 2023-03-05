{
  description = "Generate Nix expressions to build Composer packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat, ... } @ inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        composer2nix = import ./default.nix { inherit pkgs; };
        composer2nix-noDev = import ./default.nix { inherit pkgs; noDev = true; };
        app = flake-utils.lib.mkApp {
          drv = composer2nix;
          exePath = "/bin/composer2nix";
        };
        app-noDev = flake-utils.lib.mkApp {
          drv = composer2nix-noDev;
          exePath = "/bin/composer2nix";
        };
        overlays = final: prev: {
          composer2nix = composer2nix;
          composer2nix-noDev = composer2nix-noDev;
        };
      in
      {
        packages.composer2nix = composer2nix;
        packages.composer2nix-noDev = composer2nix-noDev;
        defaultPackage = composer2nix;
        apps.composer2nix = app;
        apps.composer2nix-noDev = app-noDev;
        defaultApp = app;

        devShells.default = pkgs.mkShell
          {
            buildInputs = with pkgs; [
              php
              php82Packages.composer
              nodejs-19_x
            ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
              pkgs.darwin.apple_sdk.frameworks.Security
              pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
            ];
          };
        inherit overlays;
      });
}
