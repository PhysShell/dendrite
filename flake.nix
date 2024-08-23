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
        configFile = pkgs.writeText "dendrite.yaml" ''
          version: 2
          global:
            server_name: "physshell.org"
            private_key: "$PWD/matrix_key.pem"
            jetstream:
              storage_path: "./jetstream"
            database:
              connection_string: "postgresql://dendrite:dendritepass@localhost/ddb?sslmode=disable"
            logging:
              - type: "std"
                level: "info"
          client_api:
            registration_disabled: false
          sync_api: {}
          room_server: {}
          federation_api:
            key_perspectives:
              - server_name: "matrix.org"
                keys:
                  - key_id: "ed25519:auto"
                    public_key: "Noi6WqcDj0QmPxCNQqgezwTlBKrfqehY1u2FyWP9uYw"
          media_api:
            max_file_size_bytes: 10485760
            max_thumbnail_generators: 10
          logging:
            - type: "file"
              level: "info"
              params:
                path: "./logs"
        '';
        caddyfile = pkgs.writeText "Caddyfile" ''
          physshell.org.com {
            reverse_proxy localhost:8008
          }
          
          element.physshell.org.com {
            root * ${pkgs.element-web}
            file_server
          }
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [ go dendrite pkgs.postgresql pkgs.caddy pkgs.element-web ];
          shellHook = ''
            export PATH=$PATH:$(pwd)/bin
            export PGDATA=$HOME/dendrite_postgres_data
            export PGHOST=$HOME/dendrite_postgres
            export PGPORT=5432
            export PGUSER=dendrite
            export PGPASSWORD=dendritepass

            if [ ! -d $PGDATA ]; then
              initdb --auth=trust --no-locale --encoding=UTF8
              echo "listen_addresses='127.0.0.1'" >> $PGDATA/postgresql.conf
              echo "unix_socket_directories='$PGHOST'" >> $PGDATA/postgresql.conf
            fi

            mkdir -p $PGHOST
            pg_ctl start -D $PGDATA -l $HOME/postgres.log -o "-c unix_socket_directories='$PGHOST'"
            
            if ! psql -lqt | cut -d \| -f 1 | grep -qw dendrite; then
              createuser -s dendrite
              createdb -O dendrite dendrite
            fi

            # Start Dendrite
            nohup dendrite-monolith-server -config ${configFile} > dendrite.log 2>&1 &

            # Start Caddy
            nohup caddy run --config ${caddyfile} > caddy.log 2>&1 &

            echo "Dendrite and Caddy are now running. Check dendrite.log and caddy.log for details."
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