#!/bin/bash
#--------------------------------------------------------------------
# Script to Install Prometheus Server on Linux Ubuntu
# Tested on Ubuntu 22.04, 24.04
#--------------------------------------------------------------------
VERSION="3.2.1"
PROMETHEUS_CONFIG="/etc/prometheus"
PROMETHEUS_TSDATA="/var/lib/prometheus"

cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v$VERSION/prometheus-$VERSION.linux-amd64.tar.gz

tar xvfz prometheus-$VERSION.linux-amd64.tar.gz
cd prometheus-$VERSION.linux-amd64

mv prometheus /usr/local/bin/
sudo mv promtool /usr/local/bin
rm -rf /tmp/prometheus*

mkdir -p $PROMETHEUS_CONFIG
mkdir -p $PROMETHEUS_TSDATA


cat <<EOF> $PROMETHEUS_CONFIG/prometheus.yml
# my global config
global:
  scrape_interval: 15s # 
  
# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          # - alertmanager:9093

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

EOF

useradd -rs /bin/false prometheus
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus $PROMETHEUS_CONFIG
chown prometheus:prometheus $PROMETHEUS_CONFIG/prometheus.yml
chown prometheus:prometheus $PROMETHEUS_TSDATA

cat <<EOF> /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target


[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
ExecStart=/usr/local/bin/prometheus \
  --config.file       ${PROMETHEUS_CONFIG}/prometheus.yml \
  --storage.tsdb.path ${PROMETHEUS_TSDATA}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus
systemctl status prometheus
prometheus --version
