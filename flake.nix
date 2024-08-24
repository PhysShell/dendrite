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
        go = pkgs.go_1_21;
        dendrite = pkgs.buildGoModule rec {
          pname = "dendrite";
          version = "v0.13.7";
          src = pkgs.fetchFromGitHub {
            owner = "matrix-org";
            repo = "dendrite";
            rev = version;
            sha256 = "sha256-A6rQ8zqpV6SBpiALIPMF1nZtGvUtzoiTE2Rioh3T1WA=";
          };
          vendorHash = "sha256-ByRCI4MuU8/ilbeNNOXSsTlBVHL5MkxLHItEGeGC9MQ=";
          doCheck = false;
          buildPhase = ''
            go build -o bin/ ./cmd/...
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp -r bin/* $out/bin
          '';
        };
        configFile = ./dendrite-sample.yaml;
caddyfile = pkgs.writeText "Caddyfile" ''
'';

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [ go dendrite pkgs.postgresql pkgs.caddy pkgs.element-web ];
          shellHook = ''
            export PATH=$PATH:$(pwd)/bin
            export PGDATA=$PWD/postgres_data
            export PGHOST=$PWD/postgres
            export PGPORT=5432
            export PGUSER=%some user%
            export PGPASSWORD=%some password%

            if [ ! -d $PGDATA ]; then
              initdb --auth=trust --no-locale --encoding=UTF8
              echo "listen_addresses='127.0.0.1'" >> $PGDATA/postgresql.conf
              echo "unix_socket_directories='$PGHOST'" >> $PGDATA/postgresql.conf
            fi

            mkdir -p $PGHOST
            pg_ctl start -D $PGDATA -l $PWD/postgres.log -o "-c unix_socket_directories='$PGHOST'"

            if ! psql -lqt | cut -d \| -f 1 | grep -qw dendrite; then
              createuser -s dendrite
              createdb -O dendrite dendrite
            fi

            # Start Dendrite
 #           nohup dendrite -config ${configFile} > $PWD/dendrite.log 2>&1 &

            # Start Caddy
#            nohup caddy run --config ${caddyfile} --adapter caddyfile > $PWD/caddy.log 2>&1 &

            echo *******WARNING*******
            echo FOR NOW in nix develop you need to manually start dendrite and caddy: 'sudo caddy run --config Caddyfile & dendrite --config dendrite-sample.yaml &'
            echo *******WARNING*******
            #echo "Dendrite and Caddy are now running. Check dendrite.log and caddy.log for details."
          '';
        };
        # after run for now it needs to create yser manually like so
        #createuser -s dendriteuser --pwprompt
              #createdb -O dendriteuser ddb
        packages.default = dendrite;
        apps.default = {
          type = "app";
          program = "${dendrite}/bin/dendrite";
          args = [ "-config" "${configFile}" ];
        };
      }
    );
}