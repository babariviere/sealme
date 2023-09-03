{
  description = "Utility to run kubeseal against *.sealme.* files";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    gomod2nix.url = "github:nix-community/gomod2nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.treefmt-nix.flakeModule
      ];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            inputs.gomod2nix.overlays.default
          ];
          config = {};
        };

        packages.default = pkgs.buildGoApplication {
          pname = "sealme";
          version = "0.1";
          pwd = ./.;
          src = ./.;
          modules = ./gomod2nix.toml;
        };

        treefmt = {
          projectRootFile = ".git/config";
          programs = {
            alejandra.enable = true;
            gofumpt.enable = true;
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Go tools
            go
            gopls
            gomod2nix
          ];
        };
      };
      flake = {
      };
    };
}
