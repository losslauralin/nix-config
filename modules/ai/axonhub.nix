# AxonHub — All-in-one AI development platform, unified API gateway.
# PostgreSQL + AxonHub containers managed via Arion.
{inputs, ...}: {
  lossilk.ai._.axonhub._.local = {
    nixos = {pkgs, ...}: {
      imports = [inputs.arion.nixosModules.arion];

      environment.systemPackages = [pkgs.arion pkgs.docker-client];

      virtualisation.arion.backend = "podman-socket";

      # 用 nixpkgs 打包的 arion (同为上游 0.2.2.0), 而非 flake input 的默认包:
      # input 的构建会跑自带测试, 测试 eval 其 container-systemd.nix 时会设置
      # nixpkgs 26.11 已移除的 services.journald.console → assert 失败, 整机构建挂掉.
      # 该文件上游自 2019 年未更新, 无新版本可升; nixpkgs 的同版本包可正常构建.
      virtualisation.arion.package = pkgs.arion;

      # 开机自启的 arion 服务在 clash-verge TUN/DNS 就绪前跑 pull 会失败,
      # 且 arion 生出的 unit 是 Restart=no → 一次竞速失败后永远装死。
      # 这里补 ordering + 失败重试, 直到镜像拉取/容器起来。
      systemd.services.arion-axonhub = {
        wants = ["network-online.target"];
        after = ["network-online.target"];
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 30;
        };
      };

      virtualisation.docker.enable = false;

      virtualisation.podman = {
        enable = true;
        autoPrune.enable = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };

      users.users.loss.extraGroups = ["podman"];

      virtualisation.arion.projects.axonhub.settings = {
        docker-compose.volumes = {
          postgres_data = {};
        };

        networks = {
          axonhub-network = {
            name = "axonhub-network";
            driver = "bridge";
          };
        };

        services = {
          postgres = {
            service = {
              image = "postgres:16-alpine";
              container_name = "axonhub-postgres";
              environment = {
                POSTGRES_DB = "axonhub";
                POSTGRES_USER = "axonhub";
                POSTGRES_PASSWORD = "axonhub_password";
              };
              volumes = ["postgres_data:/var/lib/postgresql/data"];
              ports = ["5432:5432"];
              networks = ["axonhub-network"];
              restart = "unless-stopped";
              healthcheck = {
                test = ["CMD-SHELL" "pg_isready -U axonhub"];
                interval = "10s";
                timeout = "5s";
                retries = 5;
              };
            };
          };

          axonhub = {
            service = {
              image = "looplj/axonhub:latest";
              container_name = "axonhub-app";
              environment = {
                AXONHUB_DB_DIALECT = "postgres";
                AXONHUB_DB_DSN = "postgres://axonhub:axonhub_password@postgres:5432/axonhub?sslmode=disable";
              };
              ports = ["8090:8090"];
              networks = ["axonhub-network"];
              restart = "unless-stopped";
              depends_on.postgres.condition = "service_healthy";
              healthcheck = {
                test = ["CMD" "wget" "--no-verbose" "--tries=1" "--spider" "http://localhost:8090/health"];
                interval = "30s";
                timeout = "10s";
                retries = 3;
                start_period = "40s";
              };
            };
          };
        };
      };
    };
  };
}
