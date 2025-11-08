# Practical Examples: CRDs with ArgoCD

This directory contains practical examples that combine Custom Resource Definitions (CRDs) with ArgoCD for GitOps workflows.

## Examples Overview

1. **Basic CRD Deployment** - Deploy CRDs using ArgoCD
2. **Application with Custom Resources** - Deploy apps that use custom resources
3. **Multi-Environment Setup** - Use Kustomize overlays for dev/staging/prod
4. **App of Apps Pattern** - Manage multiple applications declaratively
5. **Custom Controller with ArgoCD** - Deploy a controller that watches CRDs

## Example Structure

Each example follows this pattern:

```
example-name/
├── README.md           # Instructions and explanation
├── base/               # Base manifests
│   ├── crds/          # Custom Resource Definitions
│   ├── app/           # Application resources
│   └── kustomization.yaml
├── overlays/          # Environment-specific configs
│   ├── dev/
│   ├── staging/
│   └── prod/
└── argocd-app.yaml    # ArgoCD Application manifest
```

## Prerequisites

Before running these examples:

1. **EKS Cluster**: Have an EKS cluster running
2. **ArgoCD Installed**: Follow [ArgoCD setup guide](../argocd/README.md)
3. **Git Repository**: Fork or create a Git repo for your manifests
4. **kubectl Access**: Configured to access your cluster

## Quick Start

### 1. Set Up Git Repository

```bash
# Create a Git repository for your manifests
git init my-gitops-repo
cd my-gitops-repo

# Copy examples
cp -r /path/to/examples/* .

# Commit and push
git add .
git commit -m "Initial commit: ArgoCD examples"
git remote add origin <your-repo-url>
git push -u origin main
```

### 2. Update ArgoCD Application Manifests

Edit each `argocd-app.yaml` to point to your Git repository:

```yaml
spec:
  source:
    repoURL: https://github.com/YOUR-ORG/YOUR-REPO  # Change this
    targetRevision: main
    path: examples/01-basic-crd-deployment
```

### 3. Deploy Examples

```bash
# Deploy an example
kubectl apply -f examples/01-basic-crd-deployment/argocd-app.yaml

# Check status
argocd app get example-basic-crd

# View in UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080
```

## Example 1: Basic CRD Deployment

**Goal**: Deploy a CRD and custom resource using ArgoCD

**What you'll learn**:
- How to deploy CRDs with ArgoCD
- Sync wave ordering
- Resource hooks

**Directory**: [01-basic-crd-deployment](./01-basic-crd-deployment/)

```bash
kubectl apply -f 01-basic-crd-deployment/argocd-app.yaml
argocd app sync example-basic-crd
```

## Example 2: Application with Custom Resources

**Goal**: Deploy a full application that uses custom resources

**What you'll learn**:
- Using CRDs in application deployments
- Managing dependencies
- Status tracking

**Directory**: [02-app-with-custom-resources](./02-app-with-custom-resources/)

## Example 3: Multi-Environment Setup

**Goal**: Use Kustomize to deploy to dev/staging/prod

**What you'll learn**:
- Kustomize overlays with ArgoCD
- Environment-specific configurations
- Promotion workflows

**Directory**: [03-multi-environment](./03-multi-environment/)

## Example 4: App of Apps Pattern

**Goal**: Manage multiple applications declaratively

**What you'll learn**:
- App of Apps pattern
- Dependency management
- Organizational structure

**Directory**: [04-app-of-apps](./04-app-of-apps/)

## Example 5: Custom Controller

**Goal**: Deploy a controller that watches and acts on CRDs

**What you'll learn**:
- Controller deployment with ArgoCD
- RBAC for controllers
- Operator pattern

**Directory**: [05-custom-controller](./05-custom-controller/)

## Common Patterns

### Pattern 1: CRD Installation with Sync Waves

CRDs must be installed before resources that use them:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: databases.data.example.com
  annotations:
    argocd.argoproj.io/sync-wave: "0"  # Install first
---
apiVersion: data.example.com/v1
kind: Database
metadata:
  name: my-db
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Install after CRD
```

### Pattern 2: Skip CRD Deletion

Prevent ArgoCD from deleting CRDs (which would delete all instances):

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: databases.data.example.com
  annotations:
    argocd.argoproj.io/sync-options: Delete=false
```

### Pattern 3: Selective Sync

Only sync specific resources:

```yaml
spec:
  syncPolicy:
    syncOptions:
      - ApplyOutOfSyncOnly=true
```

### Pattern 4: Resource Hooks

Run jobs before/after sync:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: migration-job
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
```

## Troubleshooting

### CRD Not Found Error

If you see "CRD not found" errors:

1. Check sync wave ordering
2. Verify CRD is applied first
3. Use `kubectl get crds` to confirm installation

```bash
# Check if CRD exists
kubectl get crds | grep example.com

# Describe CRD
kubectl describe crd databases.data.example.com

# Check ArgoCD sync order
argocd app get <app-name> --show-operation
```

### Custom Resource Validation Errors

If custom resources fail validation:

1. Check the CRD schema
2. Validate your resource YAML
3. Review ArgoCD logs

```bash
# Validate locally
kubectl apply --dry-run=client -f my-resource.yaml

# Check ArgoCD application controller logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### Sync Out of Order

Resources syncing in wrong order:

1. Use sync waves
2. Check resource dependencies
3. Use sync hooks for special cases

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"  # Lower numbers sync first
```

## Best Practices

### 1. CRD Management

- Use sync wave 0 for CRDs
- Skip deletion with `Delete=false`
- Version your CRDs properly

### 2. Resource Organization

```
repo/
├── crds/              # All CRDs
├── base/              # Base configurations
├── overlays/          # Environment overlays
└── apps/              # Application definitions
```

### 3. Git Workflow

- **main branch**: Production
- **staging branch**: Staging environment
- **dev branch**: Development

### 4. Sync Policies

- **Dev**: Auto-sync with prune and self-heal
- **Staging**: Auto-sync without prune
- **Prod**: Manual sync only

### 5. Testing

Before deploying to production:

```bash
# Dry run
argocd app sync my-app --dry-run

# Preview changes
argocd app diff my-app

# Validate manifests
kubectl apply --dry-run=server -f .
```

## Progressive Delivery

For advanced deployments, consider:

1. **Argo Rollouts**: Blue-green, canary deployments
2. **Sync Windows**: Control when syncs can happen
3. **Resource Hooks**: Pre/post deployment tasks
4. **Health Checks**: Custom health assessments

## Monitoring and Observability

### Track Application Health

```bash
# Get application status
argocd app get my-app

# Watch sync progress
argocd app sync my-app --watch

# View application resources
kubectl get all -l app.kubernetes.io/instance=my-app
```

### Set Up Alerts

Configure ArgoCD notifications for:
- Sync failures
- Out of sync applications
- Health status changes

See [ArgoCD notifications docs](https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/)

## Next Steps

1. Work through each example in order
2. Customize examples for your use cases
3. Set up your own Git repository
4. Implement the App of Apps pattern
5. Explore Argo Rollouts for progressive delivery

## Resources

- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [Kustomize Documentation](https://kustomize.io/)
- [Kubernetes Operator Pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)
