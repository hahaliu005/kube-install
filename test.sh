#!/usr/bin/env bash
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh root@${node_ip} "mkdir -p /etc/kubernetes/cert && chown -R k8s /etc/kubernetes"
    scp ca*.pem ca-config.json k8s@${node_ip}:/etc/kubernetes/cert
  done