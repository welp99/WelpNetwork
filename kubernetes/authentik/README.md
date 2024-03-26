## Add helm repository
```bash
helm repo add authentik https://charts.goauthentik.io
helm repo update
helm upgrade --install authentik authentik/authentik -f values.yaml
```

## Install Authentik 
```bash
helm upgrade --install authentik authentik/authentik -f values.yml
```

## Deploy additional manifest
```bash
kubectl apply -f ingress.yml
kubectl apply -f default-headres.yml
```
