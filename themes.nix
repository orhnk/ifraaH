{ lib, ... }:
let
  themesDir = ./themes;
  entries = builtins.readDir themesDir;

  themes = builtins.listToAttrs (map (name: {
    name = lib.removeSuffix ".yaml" name;
    value = lib.importYAML (themesDir + "/${name}");
  }) (builtins.filter (n: entries.${n} == "regular" && lib.hasSuffix ".yaml" n)
       (builtins.attrNames entries)));
in
themes
