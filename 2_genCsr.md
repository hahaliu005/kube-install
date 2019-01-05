```
cd /opt/k8s && \
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 && \
mv cfssl_linux-amd64 /opt/k8s/bin/cfssl && \
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 && \
mv cfssljson_linux-amd64 /opt/k8s/bin/cfssljson && \
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 && \
mv cfssl-certinfo_linux-amd64 /opt/k8s/bin/cfssl-certinfo && \
chmod +x /opt/k8s/bin/*
```

```
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF
```

```
cat > ca-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "4Paradigm"
    }
  ]
}
EOF

```

```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
ls ca*
```

```
for node_ip in ${NODE_IPS[@]}
  do
    echo ">>> ${node_ip}"
    scp ca*.pem ca-config.json root@${node_ip}:/etc/kubernetes/cert
  done
```
