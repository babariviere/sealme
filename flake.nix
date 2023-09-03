{
  description = "Utility to run kubeseal against *.sealme.* files";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    gomod2nix.url = "github:nix-community/gomod2nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} ({withSystem, ...}: {
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
          version = "0.2.0";
          pwd = ./.;
          src = ./.;
          modules = ./gomod2nix.toml;
        };

        packages.sealme = config.packages.default;

        packages.ksecret = let
          build-inputs = with pkgs; [kubectl yq-go];
          script = (pkgs.writeScriptBin "ksecret" (builtins.readFile ./scripts/ksecret.sh)).overrideAttrs (old: {
            buildComamnd = "${old.buildCommand}\n patchShebangs $out";
          });
          completion-zsh =
            pkgs.writeTextDir "share/zsh/site-functions/_ksecret"
            ''
              compdef _ksecret ksecret
              _ksecret() {
                  service=kubectl
                  CURRENT+=2
                  words="kubectl get secrets ''${words[@]:1}"
                  _kubectl
              }
            '';
        in
          pkgs.symlinkJoin {
            name = "ksecret";
            paths = [script completion-zsh];
            buildInputs = [pkgs.makeWrapper];
            postBuild = "wrapProgram $out/bin/ksecret --prefix PATH : ${pkgs.lib.makeBinPath build-inputs}";
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
        overlays.default = final: prev:
          withSystem prev.stdenv.hostPlatform.system (
            {config, ...}: {
              sealme = config.packages.sealme;
              ksecret = config.packages.ksecret;
            }
          );
      };
    });
}
