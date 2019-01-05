```
cd /opt/k8s
```

```
cat > haproxy.cfg <<EOF
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /var/run/haproxy-admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    nbproc 1

defaults
    log     global
    timeout connect 5000
    timeout client  10m
    timeout server  10m

listen kube-master
    bind 0.0.0.0:8443
    mode tcp
    option tcplog
    balance source
    server 172.27.129.105 172.27.129.105:6443 check inter 2000 fall 2 rise 2 weight 1
    server 172.27.129.111 172.27.129.111:6443 check inter 2000 fall 2 rise 2 weight 1
    server 172.27.129.112 172.27.129.112:6443 check inter 2000 fall 2 rise 2 weight 1
EOF
```

```
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    scp haproxy.cfg root@${node_ip}:/etc/haproxy
  done
```

```
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh root@${node_ip} "systemctl enable haproxy && systemctl restart haproxy"
  done
```

```
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh root@${node_ip} "systemctl status haproxy|grep Active"
  done
```

```
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    ssh root@${node_ip} "netstat -lnpt|grep haproxy"
  done
```
