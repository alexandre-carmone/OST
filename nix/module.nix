# NixOS module: services.ostserver
#
# Runs ostserver as a system service, the same way the Debian package's
# ostserver.service does, and optionally serves the web UI with nginx
# (same nginx locations as the Debian "complete" package, see
# cmake/cpack/complete/postinst).
self:
{ config, lib, pkgs, ... }:
let
  cfg = config.services.ostserver;
  stateDir = "/var/lib/ostserver";
in
{
  options.services.ostserver = {
    enable = lib.mkEnableOption "OST, Observatoire Sans Tête";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.ostserver;
      defaultText = lib.literalExpression "ostserver from this flake";
      description = "The ostserver package to run.";
    };

    args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "--indiserver=Y" "--loglevel=1" "--grant=0" ];
      description = ''
        Command line options, see `ostserver --help`.
        `--webroot` is always set to `${stateDir}/media`.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the WebSocket port (9624) and, with webUI, port 80.";
    };

    webUI.enable = lib.mkEnableOption "serving the OST web UI with nginx on port 80";
  };

  config = lib.mkIf cfg.enable {
    users.users.ostserver = {
      isSystemUser = true;
      group = "ostserver";
      home = stateDir;
      # Serial ports and cameras, for the INDI drivers.
      extraGroups = [ "dialout" "video" ];
    };
    users.groups.ostserver = { };

    systemd.services.ostserver = {
      description = "OST - Observatoire Sans Tête";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment.QT_QPA_PLATFORM = "offscreen";
      serviceConfig = {
        User = "ostserver";
        Group = "ostserver";
        StateDirectory = "ostserver ostserver/media";
        WorkingDirectory = stateDir;
        ExecStart = "${lib.getExe cfg.package} --webroot=${stateDir}/media "
          + lib.escapeShellArgs cfg.args;
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    # ostserver advertises itself over mDNS; avahi refuses to publish for
    # non-root users unless userServices is set.
    services.avahi = {
      enable = true;
      publish.enable = true;
      publish.userServices = true;
    };

    networking.firewall.allowedTCPPorts =
      lib.optional cfg.openFirewall 9624
      ++ lib.optional (cfg.openFirewall && cfg.webUI.enable) 80;

    services.nginx = lib.mkIf cfg.webUI.enable {
      enable = true;
      # Cache for the sky survey tiles proxied below.
      appendHttpConfig = ''
        proxy_cache_path /var/cache/nginx/hips levels=1:2 keys_zone=hips_cache:10m max_size=2g inactive=90d use_temp_path=off;
      '';
      virtualHosts.ostserver = {
        default = true;
        root = "${cfg.package}/share/ostserver/www";
        locations."/ostmedia/" = {
          alias = "${stateDir}/media/";
          extraConfig = "autoindex on;";
        };
        locations."/hips-proxy/dss2color/" = {
          proxyPass = "https://alasky.cds.unistra.fr/DSS/DSSColor/";
          extraConfig = ''
            proxy_ssl_server_name on;
            proxy_set_header Host alasky.cds.unistra.fr;
            proxy_cache hips_cache;
            proxy_cache_valid 200 90d;
            proxy_cache_valid 404 10m;
          '';
        };
      };
    };
  };
}
