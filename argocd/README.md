# ArgoCD on Amazon EKS

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It watches Git repositories and automatically syncs the desired state to your cluster.

## What is GitOps?

GitOps uses Git as the single source of truth for declarative infrastructure and applications:

1. **Declarative**: Everything is defined as code in Git
2. **Versioned**: Git history provides audit trail
3. **Automated**: Changes in Git trigger automatic deployments
4. **Self-healing**: ArgoCD continuously reconciles desired vs actual state

## ArgoCD Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Git Repository                      │
│           (Manifests, Helm Charts, Kustomize)           │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ polls/watches
                     ▼
┌─────────────────────────────────────────────────────────┐
│                    ArgoCD Server                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Application │  │ Repo Server  │  │   API/UI     │  │
│  │  Controller  │  │              │  │              │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ applies resources
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Amazon EKS Cluster                          │
│    Pods, Services, Deployments, CRDs, etc.              │
└─────────────────────────────────────────────────────────┘
```

## Installation on EKS

### Prerequisites

```bash
# Verify EKS cluster access
kubectl cluster-info

# Verify kubectl version (1.24+)
kubectl version --client

# Install Helm if not already installed
# brew install helm  # macOS
# choco install kubernetes-helm  # Windows
```

### Method 1: Using kubectl (Recommended for learning)

```bash
# Create argocd namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=600s \
  deployment/argocd-server -n argocd

# Verify installation
kubectl get pods -n argocd
argocd-applicationset-controller   0/1     1            0           35m
argocd-dex-server                  0/1     1            0           35m
argocd-notifications-controller    0/1     1            0           35m
argocd-redis                       0/1     1            0           35m
argocd-repo-server                 0/1     1            0           35m
argocd-server                      0/1     1            0           35m
```



### Method 2: Using Helm

```bash
# Add ArgoCD Helm repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD with custom values
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set server.service.type=LoadBalancer

# Check installation
helm list -n argocd
kubectl get pods -n argocd
```

## Accessing ArgoCD UI

### Method 1: Port Forwarding (Quick Start)

```bash
# Forward ArgoCD server port
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access UI at: https://localhost:8080
# Username: admin
```

### Method 2: LoadBalancer (EKS with AWS LB Controller)

```bash
# Patch service to use LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get LoadBalancer URL
kubectl get svc argocd-server -n argocd

# Wait for external IP/hostname
ARGOCD_URL=$(kubectl get svc argocd-server -n argocd \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ArgoCD URL: https://$ARGOCD_URL"
```

### Method 3: Ingress with TLS (Production)

See [argocd-ingress.yaml](./argocd-ingress.yaml) for NGINX ingress configuration.

## Initial Setup

### Get Admin Password

```bash
# Get initial admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
echo "Admin password: $ARGOCD_PASSWORD"

# Login with username: admin
```

### Install ArgoCD CLI

```bash
# macOS
brew install argocd

# Linux
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Windows (using PowerShell)
$version = (Invoke-RestMethod https://api.github.com/repos/argoproj/argo-cd/releases/latest).tag_name
Invoke-WebRequest -Uri "https://github.com/argoproj/argo-cd/releases/download/$version/argocd-windows-amd64.exe" -OutFile argocd.exe
```

### Login via CLI

```bash
# Port forward if not using LoadBalancer
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Login
argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure

# Or with LoadBalancer
argocd login $ARGOCD_URL --username admin --password $ARGOCD_PASSWORD

# Change admin password
argocd account update-password
```

## Creating Your First Application

### Method 1: Using CLI

```bash
# Create an application from a Git repository
argocd app create guestbook \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Sync the application
argocd app sync guestbook

# Check status
argocd app get guestbook
```

### Method 2: Using YAML Manifest

Create an Application resource (see [example-app.yaml](./example-app.yaml)):

```bash
kubectl apply -f example-app.yaml
```

### Method 3: Using UI

1. Open ArgoCD UI
2. Click "+ New App"
3. Fill in application details:
   - **Application Name**: my-app
   - **Project**: default
   - **Sync Policy**: Manual or Automatic
   - **Repository URL**: Your Git repo
   - **Path**: Path to manifests
   - **Cluster**: https://kubernetes.default.svc
   - **Namespace**: target namespace

## ArgoCD Application Patterns

### Auto-Sync

Automatically sync when Git changes:

```yaml
spec:
  syncPolicy:
    automated:
      prune: true      # Delete resources not in Git
      selfHeal: true   # Force sync even when cluster state differs
```

### Sync Waves

Control deployment order using annotations:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Deploy after wave 0
```

### Hooks

Run jobs at specific phases:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
```

## EKS-Specific Considerations

### IAM Roles for Service Accounts (IRSA)

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-application-controller
  namespace: argocd
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/argocd-role
```

### AWS Load Balancer Controller

For production ingress setup:

```bash
# Install AWS Load Balancer Controller first
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-cluster
```

### Private Git Repositories

Add SSH key or HTTPS credentials:

```bash
# Add repository via CLI
argocd repo add https://github.com/myorg/private-repo \
  --username myuser \
  --password mypassword

# Or use SSH
argocd repo add git@github.com:myorg/private-repo.git \
  --ssh-private-key-path ~/.ssh/id_rsa
```

## Managing Multiple Clusters

Register external clusters:

```bash
# List contexts
kubectl config get-contexts

# Add cluster to ArgoCD
argocd cluster add my-other-cluster-context

# List registered clusters
argocd cluster list
```

## Projects and RBAC

Create project for multi-tenancy:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: my-project
  namespace: argocd
spec:
  description: My team's project
  sourceRepos:
    - https://github.com/myorg/*
  destinations:
    - namespace: 'my-team-*'
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
```

## Monitoring and Observability

### ArgoCD Metrics

```bash
# Prometheus metrics available at
kubectl port-forward svc/argocd-metrics -n argocd 8082:8082
curl http://localhost:8082/metrics
```

### Application Health

ArgoCD tracks resource health automatically:
- **Healthy**: Resource is running as expected
- **Progressing**: Resource is being created/updated
- **Degraded**: Resource is not functioning correctly
- **Suspended**: Resource is suspended
- **Missing**: Resource is not found in cluster

## Troubleshooting

### Check Application Status

```bash
# Get application details
argocd app get <app-name>

# Get sync status
argocd app sync-status <app-name>

# View logs
kubectl logs -n argocd deployment/argocd-application-controller
kubectl logs -n argocd deployment/argocd-server
```

### Common Issues

1. **Out of Sync**: Git and cluster differ
   - Check: `argocd app diff <app-name>`
   - Fix: `argocd app sync <app-name>`

2. **Sync Failed**: Validation or permission errors
   - Check application logs
   - Verify RBAC permissions
   - Validate YAML syntax

3. **Connection Issues**: Can't reach repository
   - Verify credentials: `argocd repo list`
   - Check network policies

## Best Practices

1. **Use App of Apps Pattern**: Manage multiple applications
2. **Enable Auto-Sync**: For non-production environments
3. **Use Sync Waves**: Control deployment order
4. **Implement RBAC**: Use projects for multi-tenancy
5. **Monitor Sync Status**: Set up alerts for sync failures
6. **Use Helm/Kustomize**: For environment-specific configs
7. **Tag Container Images**: Avoid 'latest' tag
8. **Enable Notifications**: Slack, email for sync events

## Next Steps

- Review example ArgoCD applications in this directory
- Deploy CRDs using ArgoCD (see [examples](../examples/README.md))
- Set up the App of Apps pattern
- Configure SSO authentication
- Implement progressive delivery with Argo Rollouts
