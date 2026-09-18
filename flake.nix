{
  description = "Theme your NixOS configuration consistently.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux"; # or aarch64-linux, etc.
    lib = nixpkgs.legacyPackages.${system}.lib;

    themesDir = ./themes;
    entries   = builtins.readDir themesDir;

    raw = builtins.listToAttrs (map (name: {
      name  = lib.removeSuffix ".yaml" name;
      value = lib.importYAML (themesDir + "/${name}");
    }) (builtins.filter
          (n: entries.${n} == "regular" && lib.hasSuffix ".yaml" n)
          (builtins.attrNames entries)));

    isValidColor = thing:
      if builtins.isString thing
      then (builtins.match "^[0-9a-fA-F]{6}" thing) != null
      else false;
  in {
    inherit raw;

    custom = theme: let
      with0x      = theme // (builtins.mapAttrs (_: value:
        if isValidColor value then "0x" + value else value) theme);
      withHashtag = theme // (builtins.mapAttrs (_: value:
        if isValidColor value then "#" + value else value) theme);
      themeFull   = theme // { inherit with0x withHashtag; };
    in themeFull // {
      adwaitaGtkCss = (import ./templates/adwaitaGtkCss.nix) themeFull;
      btopTheme     = (import ./templates/btopTheme.nix)     themeFull;
      discordCss    = (import ./templates/discordCss.nix)    themeFull;
      firefoxTheme  = (import ./templates/firefoxTheme.nix)  themeFull;
      ghosttyConfig = (import ./templates/ghosttyConfig.nix) themeFull;
      tmTheme       = (import ./templates/tmTheme.nix)       themeFull;
      dmenuTheme    = (import ./templates/dmenuTheme.nix)    themeFull;
    };
  } // builtins.mapAttrs (_: self.custom) raw;
}
