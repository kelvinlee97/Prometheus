#!/bin/bash

# ensure the server is up to date
sudo apt-get update -y -qq

# create a prometheus user
sudo useradd --system -r prometheus

# set variables
prometheus_version=prometheus-2.52.0.linux-amd64 ##edit

# get the prometheus from github repo (careful the version used)
if [ -e $prometheus_version.tar.gz ]; then
    echo "$prometheus_version.tar.gz already exists, skipping creation..."
else
    echo "Now downloading the package..."
    sudo wget https://github.com/prometheus/prometheus/releases/download/v2.52.0/$prometheus_version.tar.gz ##edit
    # un-tar the package
    sudo tar -xvf $prometheus_version.tar.gz
    # copy the bootstrap of prometheus
    sudo cp $prometheus_version/prometheus /usr/local/bin
    sudo cp $prometheus_version/promtool /usr/local/bin
    # copy the default configure file
    sudo mkdir /etc/prometheus
    sudo cp -rvf $prometheus_version/prometheus.yml /etc/prometheus
    # create a dir for store prometheus data
    sudo mkdir /prometheus
    sudo chown prometheus:prometheus /prometheus
fi

# configure the systemctl service for start, stop, enable service
echo "[Unit]
Description=Prometheus
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
WorkingDirectory=/prometheus
ExecStart=/usr/local/bin/prometheus --config.file /etc/prometheus/prometheus.yml

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/prometheus.service > /dev/null 2>&1

# services for start, stop, restart, status...
sudo systemctl daemon-reload
sudo systemctl start prometheus.service
sudo systemctl enable prometheus

# wait for service to ready
sleep 5

# retrieve public ip of this device
pub_ip=$(sudo su -c "curl -s ifconfig.me")

# check prometheus service http status
if [ $(curl -o /dev/null -s -w %{http_code} http://$pub_ip:9090/graph) = 200 ]; then
    echo "status code 200, Install OK!"
else
    echo "maybe goes wrong..."
fi
