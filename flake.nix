{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      # url = "git+file:///Users/delabere/src/zmk-nix";
      url = "github:delabere/zmk-nix/fix-building-on-darwin";

      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    zmk-nix,
  }: let
    forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in rec {
      default = firmware;

      firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
        name = "firmware";

        src = nixpkgs.lib.sourceFilesBySuffices self [".conf" ".keymap" ".yml"];

        board = "nice_nano_v2";
        shield = "corne_%PART% nice_view_adapter nice_view";

        zephyrDepsHash = "sha256-RnnLCRRtaLXaWkWrIjbNxcez+1o6xCZn6pQprROiOPo=";

        meta = {
          description = "ZMK firmware";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };

      # flash = zmk-nix.packages.${system}.flash.override {inherit firmware;};
      update = zmk-nix.packages.${system}.update;

      test = pkgs.stdenv.mkDerivation {
        name = "test";
        phases = ["unpackPhase" "buildPhase"];
        src = nixpkgs.lib.sourceFilesBySuffices self [".conf" ".keymap" ".yml"];

        buildInputs = [pkgs.tree];
        buildPhase = ''
          pwd
          echo $TMP/$sourceRoot
        '';
      };
    });

    devShells = forAllSystems (system: {
      default = zmk-nix.devShells.${system}.default;
    });
  };
}
