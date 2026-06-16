# AxonHub — All-in-one AI development platform, unified API gateway.
# PostgreSQL + AxonHub containers managed via Arion.
{inputs, ...}: {
  lossilk.ai._.axonhub._.local = {
    nixos = {pkgs, ...}: {
      imports = [inputs.arion.nixosModules.arion];

      environment.systemPackages = [pkgs.arion pkgs.docker-client];

      virtualisation.arion.backend = "podman-socket";

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
                AXONHUB_SERVER_API_AUTH_ALLOW_NO_AUTH = "true";
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
