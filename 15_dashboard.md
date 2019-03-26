```
cp -R addons/dashboard .
kubectl create -f dashboard
```

Request from browser `https://{node-ip}:{32729}`

```
kubectl create sa dashboard-admin -n kube-system
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
ADMIN_SECRET=$(kubectl get secrets -n kube-system | grep dashboard-admin | awk '{print $1}')
DASHBOARD_LOGIN_TOKEN=$(kubectl describe secret -n kube-system ${ADMIN_SECRET} | grep -E '^token' | awk '{print $2}')
echo ${DASHBOARD_LOGIN_TOKEN}

```

```
kubectl get secrets -n=kube-system | grep dashboard-admin
kubectl describe secrets {dashboard-admin-token} -n=kube-system
```
