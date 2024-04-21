## Introduction

Traefik is a modern HTTP reverse proxy and load balancer that makes deploying microservices easy. It is designed to handle high traffic workloads and can be used to route traffic to different services based on various criteria. Traefik is a popular choice for Kubernetes users because of its ease of use and powerful features.

# Installing helm

Helm is a package manager for Kubernetes that allows you to easily install and manage applications on your cluster. Helm uses charts to define the structure of an application and its dependencies, making it easy to deploy complex applications with a single command.

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
This will download the Helm installation script and run it to install Helm on your system.

- check the version
```bash
helm version
```
Expected output
```bash
version.BuildInfo{Version:"v3.12.0", GitCommit:"c9f554d75773799f72ceef38c51210f1842a1dea", GitTreeState:"clean", GoVersion:"go1.20.4"}
```

# Install Traefik

## Get repository

Add the Traefik Helm repository to your local Helm installation.

```bash
helm repo add traefik https://helm.traefik.io/traefik
```

- Update repo

```bash
helm repo update
```
Expected output
```bash
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "traefik" chart repository
...Successfully got an update from the "prometheus-community" chart repository
Update Complete. ⎈Happy Helming!⎈
```

## Create a namespace
Create a new namespace for Traefik to run in.

```bash
kubectl create namespace traefik
```

- check if the namespace is created

```bash
kubectl get namespaces
```
Expected output
```bash
NAME              STATUS   AGE
default           Active   79m
kube-node-lease   Active   79m
kube-public       Active   79m
kube-system       Active   79m
metallb-system    Active   78m
traefik           Active   36s
```

## Install traefik

Create a `values.yml` file to configure Traefik with the following settings:
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

This command will install Traefik in the `traefik` namespace using the configuration defined in the `values.yml` file.  

```bash
helm install --namespace=traefik traefik traefik/traefik --values=values.yml
```
Expected output
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
- check the pods
```bash
kubectl get svc --all-namespaces -o wide
```
Expected output
```bash
NAMESPACE        NAME              TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE     SELECTOR
default          kubernetes        ClusterIP      10.43.0.1       <none>        443/TCP                      105m    <none>
kube-system      kube-dns          ClusterIP      10.43.0.10      <none>        53/UDP,53/TCP,9153/TCP       105m    k8s-app=kube-dns
kube-system      metrics-server    ClusterIP      10.43.176.65    <none>        443/TCP                      105m    k8s-app=metrics-server
metallb-system   webhook-service   ClusterIP      10.43.146.200   <none>        443/TCP                      105m    component=controller
traefik          traefik           LoadBalancer   10.43.142.228   10.10.10.50   80:30639/TCP,443:31270/TCP   2m29s   app.kubernetes.io/instance=traefik-traefik,app.kubernetes.io/name=traefik
```

### Configure middleware
Middleware is a way to apply additional processing to requests before they reach the backend service. In this example, we will create a middleware that adds default headers to all requests.

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
    
Apply the middleware to the cluster.
```bash
kubectl apply -f default-headers.yml
```
- check the middleware
```bash
kubectl get middleware
```
Expected output
```bash
NAME              AGE
default-headers   12s
```

### Secure Traefik Dashboard

The Traefik dashboard is a web interface that allows you to monitor the status of Traefik and the services it routes traffic to. By default, the dashboard is not secure and can be accessed by anyone with the URL. To secure the dashboard, we will add basic authentication using a middleware.

- Install htpassword

```bash
sudo apt-get update
sudo apt-get install apache2-utils
```
**Generate a new password for the dashboard**
- Replace `<USER>` and `<PASSWORD>` with your desired username and password.
```bash
htpasswd -nb `<USER>``<PASSWORD>`| openssl base64
```
- Copy the output and add it to the `secret-dashboard.yml` file under `users`.

- Apply secret for the dashboard
- `secret-dashboard.yml`
    
    ```bash
    apiVersion: v1
    kind: Secret
    metadata:
      name: traefik-dashboard-auth
      namespace: traefik
    type: Opaque
    data:
      users: <base64_encoded_password>
    ```
```bash
kubectl apply -f secret-dashboard.yml
```
- Check the secret
```bash
kubectl get secret --namespace traefik
```
Expected output
```bash
NAME                            TYPE                 DATA   AGE
sh.helm.release.v1.traefik.v1   helm.sh/release.v1   1      36m
traefik-dashboard-auth          Opaque               1      69s
```

- add middleware for traeffik-basic-auth
- `middleware-dashboard.yml`
    
    ```bash
    apiVersion: traefik.containo.us/v1alpha1
    kind: Middleware
    metadata:
      name: traefik-basic-auth
      namespace: traefik
    spec:
      basicAuth:
        secret: traefik-dashboard-auth
    ```

```bash
kubectl apply -f middleware.yml
```
Finally, add an ingress route to the Traefik dashboard to enable access to the dashboard with basic authentication.
- `ingress-dashboard.yml`
    
    ```bash
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: traefik-dashboard
      namespace: traefik
    spec:
      entryPoints:
        - websecure
      routes:
        - match: Host(`traefik-dashboard.your-domain.com`)
          kind: Rule
          services:
            - name: api@internal
              port: 8080
          middlewares:
            - name: traefik-basic-auth
      tls:
        secretName: tls
    ```

```bash

- Apply dashboard

```bash
kubectl apply -f ingress-dashboard.yml
```

## cert-manager
Cert-manager is a Kubernetes add-on that automates the management and issuance of TLS certificates. It integrates with popular certificate authorities like Let's Encrypt and allows you to easily secure your applications with HTTPS.

- Create namespace for cert-manager

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
- check the pods
```bash
kubectl get pods --namespace cert-manager
```
- Expected output
```bash
NAME                                       READY   STATUS    RESTARTS   AGE
cert-manager-6df9b4f9c-gcqj5               1/1     Running   0          2m5s
cert-manager-6df9b4f9c-jds97               1/1     Running   0          2m5s
cert-manager-6df9b4f9c-lgvvt               1/1     Running   0          2m5s
cert-manager-cainjector-59855d5697-mgfxw   1/1     Running   0          2m5s
cert-manager-webhook-6d5454d55d-nlfrj      1/1     Running   0          2m5s
```

### letsencrypt
Let's Encrypt is a free, automated, and open certificate authority that provides TLS certificates for websites. Cert-manager integrates with Let's Encrypt to automatically issue and renew certificates for your applications.

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
    
- Apply secret
```bash
kubectl apply -f secret-cf-token.yml
```
- Apply Staging issuer
- `letsencrypt-staging.yml`
    
    ```bash
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-staging
      namespace: cert-manager
    spec:
      acme:
        email: <email>
        server: https://acme-staging-v02.api.letsencrypt.org/directory
        privateKeySecretRef:
          name: letsencrypt-staging
        solvers:
          - dns01:
              cloudflare:
                email: <email>
                apiKeySecretRef:
                  name: cloudflare-token-secret
                  key: cloudflare-token
    ```
```bash
kubectl apply -f letsencrypt-staging.yml
```
- Apply Production issuer
- `letsencrypt-production.yml`
    
    ```bash
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-production
      namespace: cert-manager
    spec:
      acme:
        email: <email>
        server: https://acme-v02.api.letsencrypt.org/directory
        privateKeySecretRef:
          name: letsencrypt-production
        solvers:
          - dns01:
              cloudflare:
                email: <email>
                apiKeySecretRef:
                  name: cloudflare-token-secret
                  key: cloudflare-token
    ```
```bash
kubectl apply -f letsencrypt-production.yml
```

### Staging/Production
We will create a certificate for the domain `lab.welpnetwork.com` using the staging issuer first to test the configuration. Once the certificate is successfully issued, we will create a certificate using the production issuer.

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

- check the orders you made for the certificate

```bash
kubectl get challenges
```

```bash
kubectl describe order <domain_name> + <order_number>
```

### Test nginx
Now that we have Traefik and cert-manager set up, we can test the configuration by deploying an Nginx web server with a TLS certificate issued by Let's Encrypt.

- `nginx.yml`
    
    ```bash
    ---
    kind: Deployment
    apiVersion: apps/v1
    metadata:
    name: nginx
    namespace: default
    labels:
        app: nginx
    spec:
    replicas: 1
    progressDeadlineSeconds: 600
    revisionHistoryLimit: 2
    strategy:
        type: Recreate
    selector:
        matchLabels:
        app: nginx
    template:
        metadata:
        labels:
            app: nginx
        spec:
        containers:
        - name: nginx
            image: nginx:latest
    ---
    apiVersion: v1
    kind: Service
    metadata:
    name: nginx
    namespace: default
    spec:
    selector:
        app: nginx
    ports:
    - name: http
        targetPort: 80
        port: 80
    ---
    apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
    name: nginx
    namespace: default
    annotations: 
        kubernetes.io/ingress.class: traefik-external
    spec:
    entryPoints:
        - websecure
    routes:
        - match: Host(`www.nginx.lab.welpnetwork.com`)  # change to your domain
        kind: Rule
        services:
            - name: nginx
            port: 80
        - match: Host(`nginx.lab.welpnetwork.com`)  # change to your domain
        kind: Rule
        services:
            - name: nginx
            port: 80
        middlewares:
            - name: default-headers
    tls:
        secretName: lab-welpnetwork-com-staging-tls
    ```
```bash
kubectl apply -f nginx.yml
```
- Check your application

You need to add the domain name to your local DNS, and you can access the Nginx web server using the domain name `nginx.lab.welpnetwork.com`.

- Delete the nginx deployment
```bash
kubectl delete -f nginx.yml
```

## Reflector
Reflector is a Kubernetes controller that automatically copies secrets and configmaps across namespaces. This can be useful for scenarios where you need to share configuration data between different parts of your cluster. We will use Reflector to automatically copy the TLS certificate secret to all namespaces in the cluster.

### Install reflector

- Add the Emberstack Helm repository

```bash
helm repo add emberstack https://emberstack.github.io/helm-charts
helm repo update
helm upgrade --install reflector emberstack/reflector
```
- Apply the reflector manifest

```bash
kubectl -n kube-system apply -f https://github.com/emberstack/kubernetes-reflector/releases/latest/download/reflector.yaml
```

- Apply certificate to all namespaces by modifying the certificate manifest to include the reflector annotations.

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

## Conclusion

Congratulations! You have successfully set up Traefik with cert-manager and reflector on your Kubernetes cluster. You can now deploy applications with automatic TLS certificate management and share configuration data across namespaces.