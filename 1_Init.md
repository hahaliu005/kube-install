## Pre requirements

### System packages
```
yum -y install epel-release && \
yum -y update && \
yum -y groupinstall "Development Tools" && \
yum -y install tar vim wget net-tools htop tmux nload && \
yum -y install conntrack ipvsadm ipset jq sysstat curl iptables libseccomp && \
yum -y install haproxy
```

```
yum install ntp -y && \
systemctl start ntpd && \
systemctl enable ntpd && \
timedatectl set-timezone Asia/Shanghai && \
timedatectl set-local-rtc 0
```

### bbr
```
wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && ./bbr.sh
```

### 
```
$ grep kube-node /etc/hosts
172.27.129.105 kube-node1 kube-node1 kube-apiserver.prod
172.27.129.111 kube-node2 kube-node2
172.27.129.112 kube-node3 kube-node3
```

```
ssh-keygen -C kube-node1

ssh-copy-id root@kube-node1
```

```
echo 'PATH=/opt/k8s/bin:$PATH' >>~/.bashrc &&
source ~/.bashrc
```

```
systemctl disable firewalld && \
systemctl stop firewalld && \
iptables -F && \
iptables -X && \
iptables -F -t nat && \
iptables -X -t nat && \
iptables -P FORWARD ACCEPT
```

```
swapoff -a && \
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab && \
cat /etc/fstab
```

```
setenforce 0 && \
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config && \
cat /etc/selinux/config
```

```
modprobe br_netfilter && \
modprobe ip_vs
```

```
cat > kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
net.ipv4.tcp_tw_recycle=0
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
EOF
cp kubernetes.conf  /etc/sysctl.d/kubernetes.conf && \
sysctl -p /etc/sysctl.d/kubernetes.conf && \
mount -t cgroup -o cpu,cpuacct none /sys/fs/cgroup/cpu,cpuacct
```

```
mkdir -p /opt/k8s/bin && \
mkdir -p /etc/kubernetes/cert && \
mkdir -p /etc/etcd/cert && \
mkdir -p /etc/flanneld/cert && \
mkdir -p /var/lib/etcd && \
mkdir -p /var/lib/kubelet && \
mkdir -p /var/lib/kube-proxy && \
mkdir -p /var/log/kubernetes && \
mkdir -p ~/.kube
```

```
curl https://raw.githubusercontent.com/docker/docker/master/contrib/check-config.sh > check-config.sh && \
bash ./check-config.sh
```

# Config environment.sh
```
source ./environment.sh
for node_ip in ${NODE_IPS[@]}
do
  echo ">>> ${node_ip}"
  scp -P ${SSH_PORT} environment.sh root@${node_ip}:/opt/k8s/bin/
done
```

