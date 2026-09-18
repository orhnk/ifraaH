{
  description = "Theme your NixOS configuration consistently.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs   = nixpkgs.legacyPackages.${system};
    lib    = pkgs.lib;

    # YAML -> JSON at eval time via yj (IFD).
    importYaml = file:
      builtins.fromJSON (builtins.readFile (pkgs.runCommand "converted-yaml.json" {} ''
        ${pkgs.yj}/bin/yj < "${file}" > "$out"
      ''));

    themesDir = ./themes;
    entries   = builtins.readDir themesDir;

    raw = builtins.listToAttrs (map (name: {
      name  = lib.removeSuffix ".yaml" name;
      value = importYaml (themesDir + "/${name}");
    }) (builtins.filter
          (n: entries.${n} == "regular" && lib.hasSuffix ".yaml" n)
          (builtins.attrNames entries)));

    # Accept both "rrggbb" and "#rrggbb".
    isHex = s:
      builtins.isString s && (builtins.match "^#?[0-9a-fA-F]{6}$" s) != null;
    bare = s: lib.removePrefix "#" s;

    custom = theme: let
      # Hoist palette.baseXX to the top level and normalise to bare hex,
      # so downstream templates can add their own prefix.
      meta    = removeAttrs theme [ "palette" ];
      palette = builtins.mapAttrs (_: v: if isHex v then bare v else v) theme.palette;
      flat    = meta // palette;

      with0x      = flat // builtins.mapAttrs (_: v: "0x" + v) palette;
      withHashtag = flat // builtins.mapAttrs (_: v: "#" + v) palette;
      themeFull   = flat // { inherit with0x withHashtag; };
    in themeFull // {
      adwaitaGtkCss = (import ./templates/adwaitaGtkCss.nix) themeFull;
      btopTheme     = (import ./templates/btopTheme.nix)     themeFull;
      discordCss    = (import ./templates/discordCss.nix)    themeFull;
      firefoxTheme  = (import ./templates/firefoxTheme.nix)  themeFull;
      ghosttyConfig = (import ./templates/ghosttyConfig.nix) themeFull;
      tmTheme       = (import ./templates/tmTheme.nix)       themeFull;
      dmenuTheme    = (import ./templates/dmenuTheme.nix)    themeFull;
    };
  in {
    inherit raw custom;

    # Apply custom to each theme so self.3024, self.gruvbox, ... are full
    # attrsets, not the custom function.
  } // builtins.mapAttrs (_: theme: custom theme) raw;
}
