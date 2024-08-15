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
          version = "v0.13.7"; # Обновите до последней версии Dendrite
          src = pkgs.fetchFromGitHub {
            owner = "matrix-org";
            repo = "dendrite";
            rev = version;
            sha256 = "sha256-A6rQ8zqpV6SBpiALIPMF1nZtGvUtzoiTE2Rioh3T1WA="; # Обновите с правильным SHA256
          };
          vendorHash = "sha256-ByRCI4MuU8/ilbeNNOXSsTlBVHL5MkxLHItEGeGC9MQ="; # Обновите с правильным SHA256
          doCheck = false; # Отключаем тесты на данный момент
          buildPhase = ''
            go build -o bin/ ./cmd/...
	     # make install
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp -r bin/* $out/bin
          '';
        };
        configFile = pkgs.writeText "dendrite.yaml" ''
          # Здесь разместите вашу конфигурацию Dendrite
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [ go dendrite pkgs.postgresql ];
          shellHook = ''
            export PATH=$PATH:$(pwd)/bin
	    export PGDATA=$PWD/postgres_data
	    export PGHOST=$PWD/postgres
	    export PGPORT=5432
	    #export PGUSER=dendrite
 	    #export PGPASSWORD=dendritepass
            if [ ! -d $PGDATA ]; then
		initdb --auth=trust --no-locale --encoding=UTF8
		echo "listen_addresses='127.0.0.1'" >> $PGDATA/postgresql.conf
		echo "unix_socket_directories='$PGHOST'" >> $PGDATA/postgresql.conf		
	    fi

	    mkdir -p $PGHOST
	    pg_ctl start -D $PGDATA -l postgres.log -o "-c unix_socket_directories='$PGHOST'"
           # sleep 3  # Дать время PostgreSQL для запуска
           # if ! psql -lqt | cut -d \| -f 1 | grep -qw dendrite; then
		#createuser -s dendrite
		#createdb -O dendrite dendrite
	    #fi
          '';
        };
        # after run for now it needs to create yser manually like so
        #createuser -s dendriteuser --pwprompt
	#createdb -O dendriteuser ddb
        packages.default = dendrite;
        apps.default = {
          type = "app";
          program = "${dendrite}/bin/dendrite";
          # Пример конфигурации, настройте по необходимости
          args = [ "-config" "${configFile}" ];
        };
      }
    );
}
