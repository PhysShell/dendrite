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
        go = pkgs.go_1_21; # Or any other suitable Go version

        dendrite = pkgs.buildGoModule rec {
          pname = "dendrite";
          version = "v0.15.1"; # Update to the latest Dendrite version

          src = pkgs.fetchFromGitHub {
            owner = "matrix-org";
            repo = "dendrite";
            rev = version;
            sha256 = "sha256-…"; # Update with the correct SHA256
          };

          vendorSha256 = "sha256-…"; # Update with the correct SHA256

          doCheck = false; # Disabling tests for now

          buildPhase = ''
            make install
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp -r ./bin/* $out/bin
          '';
        };
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

          # Example configuration, adjust as needed
          configFile = "dendrite.yaml";
          copyConfig = true;

          args = [ "-config" configFile ];
        };
      }
    );
}