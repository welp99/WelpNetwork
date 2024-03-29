## Clone git repository

```bash
git clone https://github.com/wazuh/wazuh-kubernetes.git -b v4.7.3 --depth=1
cd wazuh-kubernetes
```

## Setup SSL Certificate

You can generate self-signed certificates for the Wazuh indexer cluster using the provide script or provide your own.

- Generate indexer self-signed certificate

```bash
wazuh/certs/indexer_cluster/generate_certs.sh
```

You can generate self-signed certificates for the Wazuh dashboard cluster using the provide script or provide your own.

- Generate dashboard self-signed certificate

```bash
wazuh/certs/dashboard_http/generate_certs.sh
```

The required certificates are imported via secretGenerator on the `kustomization.yml` file:

We will use traefik and cert-manager for accesing the dashboard

## Deploy wazuh cluster

<aside>
💡 Before deploying we will adapt some manifest for our environment

</aside>

### Wazuh Dashboard

- First we need to change the dashboard service manifest to a `ClusterIP` type
- `wazuh/indexer_stack/wazuh-dashboard/dashboard-svc.yaml`

```bash
apiVersion: v1
kind: Service
metadata:
  name: wazuh-dashboard
  namespace: wazuh
  labels:
    app: wazuh-dashboard
spec:
  type: ClusterIP
  selector:
    app: wazuh-dashboard
  ports:
    - name: wazuh-dashboard
      port: 443
      targetPort: 5601
```

- Then we will add an ingressRoute to our reverse-proxy
- Create a file name `ingress.yml` to route external trafic to the dashboard
- `wazuh/indexer_stack/wazuh-dashboard/ingress.yml`

```bash
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: wazuh-dashboard
  namespace: wazuh
  annotations: 
    kubernetes.io/ingress.class: traefik-external
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`www.wazuh.your-domain.com`)  # change to your domain
      kind: Rule
      services:
        - name: wazuh-dashboard
          port: 443
    - match: Host(`wazuh.your-domain.com`)  # change to your domain
      kind: Rule
      services:
        - name: wazuh-dashboard
          port: 443
      middlewares:
        - name: default-headers
  tls:
    secretName: tls  # change to your cert name
```

- Finally add the default headers via a new manifest file `default-headers.yml`
- `wazuh/indexer_stack/wazuh-dashboard/default-headers.yml`

```bash
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: default-headers
  namespace: wazuh
spec:
  headers:
    browserXssFilter: true
    contentTypeNosniff: true
    forceSTSHeader: true
    stsIncludeSubdomains: true
    stsPreload: true
    stsSeconds: 15552000
    customFrameOptionsValue: SAMEORIGIN
    customRequestHeaders:
      X-Forwarded-Proto: https
```

### Kustomization

We just add two manifest to deploy them we need to add them to our `kustomization.yml`

- `wazuh/kustomization.yml`

```bash
# Copyright (C) 2019, Wazuh Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Adds wazuh namespace to all resources.
namespace: wazuh

secretGenerator:
  - name: indexer-certs
    files:
      - certs/indexer_cluster/root-ca.pem
      - certs/indexer_cluster/node.pem
      - certs/indexer_cluster/node-key.pem
      - certs/indexer_cluster/dashboard.pem
      - certs/indexer_cluster/dashboard-key.pem
      - certs/indexer_cluster/admin.pem
      - certs/indexer_cluster/admin-key.pem
      - certs/indexer_cluster/filebeat.pem
      - certs/indexer_cluster/filebeat-key.pem
  - name: dashboard-certs
    files:
      - certs/dashboard_http/cert.pem
      - certs/dashboard_http/key.pem
      - certs/indexer_cluster/root-ca.pem

configMapGenerator:
  - name: indexer-conf
    files:
      - indexer_stack/wazuh-indexer/indexer_conf/opensearch.yml
      - indexer_stack/wazuh-indexer/indexer_conf/internal_users.yml
  - name: wazuh-conf
    files:
      - wazuh_managers/wazuh_conf/master.conf
      - wazuh_managers/wazuh_conf/worker.conf
  - name: dashboard-conf
    files:
      - indexer_stack/wazuh-dashboard/dashboard_conf/opensearch_dashboards.yml

resources:
  - base/wazuh-ns.yaml
  - base/storage-class.yaml

  - secrets/wazuh-api-cred-secret.yaml
  - secrets/wazuh-authd-pass-secret.yaml
  - secrets/wazuh-cluster-key-secret.yaml
  - secrets/dashboard-cred-secret.yaml
  - secrets/indexer-cred-secret.yaml

  - wazuh_managers/wazuh-cluster-svc.yaml
  - wazuh_managers/wazuh-master-svc.yaml
  - wazuh_managers/wazuh-workers-svc.yaml
  - wazuh_managers/wazuh-master-sts.yaml
  - wazuh_managers/wazuh-worker-sts.yaml

  - indexer_stack/wazuh-indexer/indexer-svc.yaml
  - indexer_stack/wazuh-indexer/cluster/indexer-api-svc.yaml
  - indexer_stack/wazuh-indexer/cluster/indexer-sts.yaml

  - indexer_stack/wazuh-dashboard/dashboard-svc.yaml
  - indexer_stack/wazuh-dashboard/dashboard-deploy.yaml
  - indexer_stack/wazuh-dashboard/ingress.yml
  - indexer_stack/wazuh-dashboard/default-headers.yml

```

### Storage class

We will used longhorn as storage class, to do so we will modify the provisioner storage class in the manifest.  

```bash
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: wazuh-storage

provisioner: driver.longhorn.io
```

### Deploy Wazuh

Now we can deploy wazuh : 

```bash
kubectl apply -k envs/local-env/
```

- **Deployments**

```bash
kubectl get deployments -n wazuh
```

![deployment](../SIEM-Wazuh(k3s)/src/deployment.png)

- **Statefulset**

```bash
kubectl get statefulsets -n wazuh
```

![statefulset](../SIEM-Wazuh(k3s)/src/statefulset.png)

- **Pods**

```bash
kubectl get pods -n wazuh
```

![pods](../SIEM-Wazuh(k3s)/src/pods.png)

- **Services**

```bash
kubectl get services -o wide -n wazuh
```

![services](../SIEM-Wazuh(k3s)/src/services.png)