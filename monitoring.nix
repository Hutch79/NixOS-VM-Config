{ config, pkgs, ... }:

{
  # Log and metrics shipping (configure URLs)
  # services.alloy = {
  #   enable = true;
  #   config = ''
  #     // Metrics from Unix system
  #     prometheus.exporter.unix "node" {
  #       set_collectors = ["cpu", "diskstats", "filesystem", "loadavg", "meminfo", "netdev", "stat", "time", "uname"]
  #     }
  #
  #     prometheus.scrape "node" {
  #       targets = prometheus.exporter.unix.node.targets
  #       forward_to = [prometheus.remote_write.local.receiver]
  #     }
  #
  #     prometheus.remote_write "local" {
  #       endpoint {
  #         url = "http://your-prometheus-server:9090/api/v1/write"  # Change to your Prometheus remote write URL
  #       }
  #     }
  #
  #     // Logs from systemd journal
  #     loki.source.journal "journal" {
  #       forward_to = [loki.write.local.receiver]
  #       labels = {
  #         job = "systemd-journal",
  #         host = "${config.networking.hostName}",
  #       }
  #       relabel_rules = [
  #         rule {
  #           source_labels = ["__journal__systemd_unit"]
  #           target_label = "unit"
  #         }
  #       ]
  #     }
  #
  #     // Logs from Docker containers
  #     loki.source.docker "docker" {
  #       forward_to = [loki.write.local.receiver]
  #       host = "unix:///var/run/docker.sock"
  #       labels = {
  #         job = "docker",
  #         host = "${config.networking.hostName}",
  #       }
  #       relabel_rules = [
  #         rule {
  #           source_labels = ["__docker_container_name"]
  #           target_label = "container"
  #         }
  #       ]
  #     }
  #
  #     loki.write "local" {
  #       endpoint {
  #         url = "http://your-loki-server:3100/loki/api/v1/push"  # Change this to your Loki URL
  #       }
  #     }
  #   '';
  # };
}