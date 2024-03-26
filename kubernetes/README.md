# Installing helm

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

```bash
helm version
```

```bash
version.BuildInfo{Version:"v3.12.0", GitCommit:"c9f554d75773799f72ceef38c51210f1842a1dea", GitTreeState:"clean", GoVersion:"go1.20.4"}
```

# Install Traefik

### Get repository

```bash
helm repo add traefik https://helm.traefik.io/traefik
```

- Update repo

```bash
helm repo update
```

```bash
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "traefik" chart repository
...Successfully got an update from the "prometheus-community" chart repository
Update Complete. ⎈Happy Helming!⎈
```

### Create a namespace

```bash
kubectl create namespace traefik
```

- check if the namespace is created

```bash
kubectl get namespaces
```

```bash
NAME              STATUS   AGE
default           Active   79m
kube-node-lease   Active   79m
kube-public       Active   79m
kube-system       Active   79m
metallb-system    Active   78m
traefik           Active   36s
```

### Install traefik

- `values.yml`
    
    ```bash
    globalArguments:
      - "--global.sendanonymoususage=false"
      - "--global.checknewversion=false"
    
    additionalArguments:
      - "--serversTransport.insecureSkipVerify=true"
      - "--log.level=INFO"
    
    deployment:
      enabled: true
      replicas: 3
      annotations: {}
      podAnnotations: {}
      additionalContainers: []
      initContainers: []
    
    ports:
      web:
        redirectTo:
          port: websecure
          priority: 10
      websecure:
        tls:
          enabled: true
          
    ingressRoute:
      dashboard:
        enabled: false
    
    providers:
      kubernetesCRD:
        enabled: true
        ingressClass: traefik-external
        allowExternalNameServices: true
      kubernetesIngress:
        enabled: true
        allowExternalNameServices: true
        publishedService:
          enabled: false
    
    rbac:
      enabled: true
    
    service:
      enabled: true
      type: LoadBalancer
      annotations: {}
      labels: {}
      spec:
        loadBalancerIP: 10.10.10.50 # this should be an IP in the MetalLB range
      loadBalancerSourceRanges: []
      externalIPs: []
    ```
    

```bash
helm install --namespace=traefik traefik traefik/traefik --values=values.yml
```

```bash
NAME: traefik
LAST DEPLOYED: Thu Mar 21 19:52:26 2024
NAMESPACE: traefik
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Traefik Proxy v2.11.0 has been deployed successfully on traefik namespace !
```

```bash
kubectl get svc --all-namespaces -o wide
```

```bash
NAMESPACE        NAME              TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE     SELECTOR
default          kubernetes        ClusterIP      10.43.0.1       <none>        443/TCP                      105m    <none>
kube-system      kube-dns          ClusterIP      10.43.0.10      <none>        53/UDP,53/TCP,9153/TCP       105m    k8s-app=kube-dns
kube-system      metrics-server    ClusterIP      10.43.176.65    <none>        443/TCP                      105m    k8s-app=metrics-server
metallb-system   webhook-service   ClusterIP      10.43.146.200   <none>        443/TCP                      105m    component=controller
traefik          traefik           LoadBalancer   10.43.142.228   10.10.10.50   80:30639/TCP,443:31270/TCP   2m29s   app.kubernetes.io/instance=traefik-traefik,app.kubernetes.io/name=traefik
```

### middleware

- `default-headers.yml`
    
    ```bash
    apiVersion: traefik.containo.us/v1alpha1
    kind: Middleware
    metadata:
      name: default-headers
      namespace: default
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
    

```bash
kubectl apply -f default-headers.yml
```

```bash
kubectl get middleware
```

```bash
NAME              AGE
default-headers   12s
```

### dashboard

- Install htpassword

```bash
sudo apt-get update
sudo apt-get install apache2-utils
```

- Generate credential

```bash
htpasswd -nb welp 8nxdtawpSjqLxCWFBv | openssl base64
```


- apply secret

```bash
kubectl apply -f secret-dashboard.yml
```

```bash
kubectl get secret --namespace traefik
```

```bash
NAME                            TYPE                 DATA   AGE
sh.helm.release.v1.traefik.v1   helm.sh/release.v1   1      36m
traefik-dashboard-auth          Opaque               1      69s
```

- add middleware for traeffik-basic-auth

```bash
kubectl apply -f middleware.yml
```

- Apply dashboard

```bash
kubectl apply -f ingress.yml
```

### cert-manager

- Create namespace

```bash
kubectl create namespace cert-manager
```

- add cert-manager repository

```bash
helm repo add jetstack https://charts.jetstack.io
```

- update repository

```bash
helm repo update
```

- Apply crds

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml
```

- Install cert-manager with helm
- `values.yml`
    
    ```bash
    installCRDs: false
    replicaCount: 3
    extraArgs:
      - --dns01-recursive-nameservers=1.1.1.1:53,9.9.9.9:53
      - --dns01-recursive-nameservers-only
    podDnsPolicy: None
    podDnsConfig:
      nameservers:
        - 1.1.1.1
        - 9.9.9.9
    ```
    

```bash
helm install cert-manager jetstack/cert-manager --namespace cert-manager --values=values.yml --version v1.9.1
```

```bash
kubectl get pods --namespace cert-manager
```

```bash
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-6df9b4f9c-gcqj5               1/1     Running   0          2m5s
cert-manager-6df9b4f9c-jds97               1/1     Running   0          2m5s
cert-manager-6df9b4f9c-lgvvt               1/1     Running   0          2m5s
cert-manager-cainjector-59855d5697-mgfxw   1/1     Running   0          2m5s
cert-manager-webhook-6d5454d55d-nlfrj      1/1     Running   0          2m5s
```

### letsencrypt

- create a secret with api token from cloudflare
- `secret-cf-token.yml`
    
    ```bash
    ---
    apiVersion: v1
    kind: Secret
    metadata:
      name: cloudflare-token-secret
      namespace: cert-manager
    type: Opaque
    stringData:
      cloudflare-token: <api_token> # be sure you are generating an API token and not a global API key https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/#api-token
    ```
    

```bash
kubectl apply -f secret-cf-token.yml
```

```bash
kubectl apply -f letsencrypt-staging.yml
```

```bash
kubectl apply -f letsencrypt-production.yml
```

### Staging/Production

- `lab-welpnetwork-com`
    
    ```bash
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: lab-welpnetwork-com
      namespace: default
    spec:
      secretName: lab-welpnetwork-com-staging-tls
      issuerRef:
        name: letsencrypt-staging
        kind: ClusterIssuer
      commonName: "*.lab.welpnetwork.com"
      dnsNames:
      - "lab.welpnetwork.com"
      - "*.lab.welpnetwork.com"
    ```
    

```bash
kubectl apply -f lab-welpnetwork-com.yml
```

- check the orders you made

```bash
kubectl get challenges
```

```bash
kubectl describe order <domain_name> + <order_number>
```

### Test nginx

```bash
kubectl apply -f nginx.yml
```

```bash
kubectl delete -f nginx.yml
```

## Reflector

### Install reflector

```bash
helm repo add emberstack https://emberstack.github.io/helm-charts
helm repo update
helm upgrade --install reflector emberstack/reflector
```

```bash
kubectl -n kube-system apply -f https://github.com/emberstack/kubernetes-reflector/releases/latest/download/reflector.yaml
```

- apply certificate to all namespaces

```bash
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: lab-welpnetwork-com
  namespace: default
spec:
  secretName: lab-welpnetwork-com-tls
  secretTemplate:
    annotations:
      reflector.v1.k8s.emberstack.com/reflection-allowed: "true"
      reflector.v1.k8s.emberstack.com/reflection-auto-enabled: "true"
  issuerRef:
    name: letsencrypt-production
    kind: ClusterIssuer
  commonName: "*.lab.welpnetwork.com"
  dnsNames:
  - "lab.welpnetwork.com"
  - "*.lab.welpnetwork.com"
```