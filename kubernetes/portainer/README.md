## Add helm repo

```bash
helm repo add portainer https://portainer.github.io/k8s/
helm repo update
```

## Install portainer

```bash
helm upgrade --install --create-namespace -n portainer portainer portainer/portainer 

```

## Deploy Manifest

```bash
kubectl apply -f ./portainer/
```