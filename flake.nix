{
  description = "Dendrite Matrix homeserver flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        go = pkgs.go_1_21; # Или любая другая подходящая версия Go
        dendrite = pkgs.buildGoModule rec {
          pname = "dendrite";
          version = "v0.15.1"; # Обновите до последней версии Dendrite
          src = pkgs.fetchFromGitHub {
            owner = "matrix-org";
            repo = "dendrite";
            rev = version;
            sha256 = "sha256-0q6mscfs4qk42f9qikidyld6sxnn0prj02r0ls0s8mx97brx1ah3"; # Обновите с правильным SHA256
          };
          vendorSha256 = "sha256-0vqsn1z12amr26qhky1kf13nca77y25wzbbk6ik1k49ashyf7drj"; # Обновите с правильным SHA256
          doCheck = false; # Отключаем тесты на данный момент
          buildPhase = ''
            make install
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp -r ./bin/* $out/bin
          '';
        };
        configFile = pkgs.writeText "dendrite.yaml" ''
          # Здесь разместите вашу конфигурацию Dendrite
        '';
      in
      {
        devShells.${system}.default = pkgs.mkShell {
          buildInputs = [ go dendrite ];
          shellHook = ''
            export PATH=$PATH:$(pwd)/bin
          '';
        };
        packages.${system}.default = dendrite;
        apps.${system}.dendrite = {
          type = "app";
          program = "${dendrite}/bin/dendrite";
          # Пример конфигурации, настройте по необходимости
          args = [ "-config" "${configFile}" ];
        };
      }
    );
}
