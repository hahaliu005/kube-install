```
cd /opt/k8s
```

```
cat > docker.service <<"EOF"
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.io

[Service]
Environment="PATH=/opt/k8s/bin:/bin:/sbin:/usr/bin:/usr/sbin"
EnvironmentFile=-/run/flannel/docker
ExecStart=/opt/k8s/bin/dockerd --log-level=error $DOCKER_NETWORK_OPTIONS
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure
RestartSec=5
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Delegate=yes
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
```

```
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    scp -P ${SSH_PORT} docker.service root@${node_ip}:/etc/systemd/system/
  done
```

# Add log rotate
```
cat > daemon.json <<"EOF"
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "512m",
    "max-file": "5"
  }
}
EOF
```

```
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    scp -P ${SSH_PORT} daemon.json root@${node_ip}:/etc/docker/daemon.json
  done
```

```
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh -p ${SSH_PORT} root@${node_ip} "systemctl daemon-reload && systemctl enable docker && systemctl restart docker"
  done
```

```
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh -p ${SSH_PORT} root@${node_ip} "systemctl status docker|grep Active"
  done
```

```
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh -p ${SSH_PORT} root@${node_ip} "/usr/sbin/ip addr show flannel.1 && /usr/sbin/ip addr show docker0"
  done
```
