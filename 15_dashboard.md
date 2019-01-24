```
cp -R addons/dashboard .
kubectl create -f dashboard
```

Request from browser `https://{node-ip}:{32729}`

```
kubectl get secrets -n=kube-system | grep dashboard-admin
kubectl describe secrets {dashboard-admin-token} -n=kube-system
```
