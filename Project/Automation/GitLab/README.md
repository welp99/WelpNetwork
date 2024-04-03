# **GitLab CI/CD**

## **GitLab Runner**

GitLab Runner is a lightweight, highly scalable agent that picks up build jobs from GitLab CI/CD and runs them. It's written in Go and can be deployed as a single binary with no external dependencies, on any platform. GitLab Runner works by connecting to a GitLab instance and asking for jobs. It can run multiple jobs concurrently and can scale horizontally by adding more runners. It's compatible with various types of executors, meaning it can execute jobs in different environments like Docker, Kubernetes, Virtual Machines, and even on bare metal. This flexibility allows you to use GitLab Runner in a variety of deployment scenarios, from simple web apps to complex Kubernetes deployments.

## **GitLab Pipelines**

GitLab pipelines are a powerful feature of GitLab CI/CD that allows you to define a series of tasks that get executed in stages. These tasks can include building your application, running tests, and deploying to various environments. Pipelines are defined in a **`.gitlab-ci.yml`** file at the root of your repository, making it easy to version control and collaborate on your CI/CD process. Each step in the pipeline can be configured to run in a specific environment, ensuring that your code is built, tested, and deployed in an automated and consistent manner. GitLab pipelines support complex workflows, including parallel and sequential execution of tasks, manual triggers for specific stages, and the ability to pause and resume tasks. This makes it an ideal tool for automating the deployment of Kubernetes manifests, as it can handle the complexity of building, testing, and deploying microservices across different environments.

## Create a gitlab runner on k3s cluster

- Gitlab helm repo

```bash
helm repo add gitlab https://charts.gitlab.io
```

- update

```bash
helm repo update gitlab
```

- install gitlab runner

```bash
helm install --namespace gitlab-runner --create-namespace gitlab-runner -f values.yml gitlab/gitlab-runner
```
