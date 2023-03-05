{ pkgs ? import <nixpkgs> {
    inherit system;
  }
, system ? builtins.currentSystem
, noDev ? false
, php ? pkgs.php
, phpPackages ? pkgs.phpPackages
}:

let
  condFilterSrc = origPath: type:
    let
      path = (toString origPath);
      base = baseNameOf path;
      parentDir = baseNameOf (dirOf path);

      matchesSuffix = pkgs.lib.any (suffix: pkgs.lib.hasSuffix suffix base) [
        ".php"
      ];

      isComposerFile = pkgs.lib.hasPrefix "composer" base && !(pkgs.lib.hasInfix "tests" path);
      isSourceFile = parentDir == "Composer2Nix";
      isTestDir = type == "directory" && pkgs.lib.hasInfix "tests" path;
    in
    (type == "directory" || matchesSuffix || isComposerFile || isSourceFile) && !isTestDir;

  composerEnv = import ./src/Composer2Nix/composer-env.nix {
    inherit (pkgs) stdenv lib writeTextFile fetchurl unzip;
    inherit php phpPackages condFilterSrc;
  };
in
import ./php-packages.nix {
  inherit composerEnv noDev;
  inherit (pkgs) fetchurl fetchgit fetchhg fetchsvn;
}
