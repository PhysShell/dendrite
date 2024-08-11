*Запусти Dendrite в development shell:**

   ```bash
   nix develop
   git clone https://github.com/matrix-org/dendrite.git
   cd dendrite
   go build -v ./cmd/dendrite
   cp dendrite.yaml.example dendrite.yaml
   ./dendrite -config dendrite.yaml
   ```

**Сборка пакета Dendrite:**

   ```bash
   nix build
   ```

**Запуск Dendrite как сервиса (systemd):**

   ```bash
   sudo nixos-rebuild switch --flake .#dendrite
   ```

**Получение актуальных хэшей**

1. **pkgs.fetchFromGitHub:**

   * **`sha256`**: Этот хэш относится к архиву с исходным кодом, который загружается с GitHub.
   * **Как получить**:
     1. Перейди на страницу релиза нужной версии Dendrite на GitHub.
     2. Найди ссылку для скачивания исходного кода в формате `.tar.gz` или `.zip`.
     3. Скопируй URL этой ссылки.
     4. Используй команду `nix-prefetch-url` для получения хэша:
        ```bash
        nix-prefetch-url --unpack <URL архива с исходным кодом>
        ```
     5. Эта команда выведет SHA256 хэш, который нужно вставить в `sha256` в твоем flake.

2. **`vendorSha256`**:

   * Этот хэш относится к зависимостям проекта Dendrite (библиотекам, которые он использует), которые находятся в директории `vendor`.
   * **Как получить**:
     1. Клонируй репозиторий Dendrite: `git clone https://github.com/matrix-org/dendrite.git`
     2. Перейди в директорию проекта: `cd dendrite`
     3. Выполни команду `go mod vendor`, чтобы загрузить зависимости в директорию `vendor`.
     4. Вычисли хэш директории `vendor`:
        ```bash
        nix-hash --type sha256 --base32 vendor
        ```
     5. Вставь полученный хэш в `vendorSha256` в твоем flake.


Привет! Конечно, помогу создать flake для Dendrite в NixOS без использования `nix-env`.

Вот flake, который отражает процесс установки и запуска Dendrite, который ты описал:

```nix
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
```
