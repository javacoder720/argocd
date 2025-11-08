# Example 3: Multi-Environment Setup with Kustomize

This example demonstrates how to use Kustomize overlays to deploy the same application to different environments (dev, staging, production) with ArgoCD.

## What You'll Learn

- Use Kustomize for environment-specific configurations
- Deploy to multiple environments from one codebase
- Manage environment differences declaratively
- Implement promotion workflows

## Architecture

```
Base Configuration
      │
      ├─── Dev Overlay
      │    ├── 1 replica
      │    ├── Small resources
      │    └── No backups
      │
      ├─── Staging Overlay
      │    ├── 2 replicas
      │    ├── Medium resources
      │    └── Weekly backups
      │
      └─── Prod Overlay
           ├── 5 replicas
           ├── Large resources
           └── Daily backups
```

## Directory Structure

```
03-multi-environment/
├── base/
│   ├── kustomization.yaml
│   ├── database-crd.yaml
│   ├── database.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── overlays/
│   ├── dev/
│   │   ├── kustomization.yaml
│   │   ├── database-patch.yaml
│   │   └── deployment-patch.yaml
│   ├── staging/
│   │   ├── kustomization.yaml
│   │   ├── database-patch.yaml
│   │   └── deployment-patch.yaml
│   └── prod/
│       ├── kustomization.yaml
│       ├── database-patch.yaml
│       └── deployment-patch.yaml
└── argocd-apps/
    ├── dev.yaml
    ├── staging.yaml
    └── prod.yaml
```

## Base Configuration

The base contains common resources shared across all environments.

## Environment Overlays

### Dev Environment
- 1 replica
- Minimal resources
- No backups
- Auto-sync enabled

### Staging Environment
- 2 replicas
- Medium resources
- Weekly backups
- Auto-sync enabled

### Production Environment
- 5 replicas
- Maximum resources
- Daily backups
- Manual sync only

## Deployment

### Deploy All Environments

```bash
# Deploy dev
kubectl apply -f argocd-apps/dev.yaml
argocd app sync myapp-dev

# Deploy staging
kubectl apply -f argocd-apps/staging.yaml
argocd app sync myapp-staging

# Deploy production
kubectl apply -f argocd-apps/prod.yaml
# Production requires manual sync
argocd app sync myapp-prod
```

### Deploy Single Environment

```bash
# Just deploy dev
kubectl apply -f argocd-apps/dev.yaml
```

## Testing Locally

```bash
# Preview dev environment
kubectl kustomize overlays/dev

# Preview staging
kubectl kustomize overlays/staging

# Preview production
kubectl kustomize overlays/prod

# Apply locally (without ArgoCD)
kubectl apply -k overlays/dev
```

## Verify Deployments

```bash
# Check dev
kubectl get all -n dev
kubectl get database -n dev

# Check staging
kubectl get all -n staging
kubectl get database -n staging

# Check production
kubectl get all -n production
kubectl get database -n production
```

## Promotion Workflow

### Promote from Dev to Staging

1. Test in dev environment
2. Update staging overlay if needed
3. Sync staging application

```bash
# Verify dev is working
kubectl get pods -n dev

# Sync to staging
argocd app sync myapp-staging

# Monitor staging
argocd app get myapp-staging
```

### Promote from Staging to Production

1. Verify staging is stable
2. Review production overlay
3. Manually sync production

```bash
# Check staging health
argocd app get myapp-staging

# Review production diff
argocd app diff myapp-prod

# Manually sync production
argocd app sync myapp-prod
```

## Customization Examples

### Change Image Version

Edit base image, then override in overlays:

```yaml
# overlays/prod/kustomization.yaml
images:
  - name: myapp
    newTag: v2.0.0  # Production uses specific version
```

### Add Environment-Specific ConfigMap

```yaml
# overlays/prod/kustomization.yaml
configMapGenerator:
  - name: app-config
    literals:
      - LOG_LEVEL=warn
      - CACHE_ENABLED=true
```

### Patch Resources

```yaml
# overlays/prod/deployment-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 5
  template:
    spec:
      containers:
      - name: app
        resources:
          requests:
            cpu: 1
            memory: 2Gi
          limits:
            cpu: 2
            memory: 4Gi
```

## Common Patterns

### Pattern 1: Namespace per Environment

```yaml
# overlays/dev/kustomization.yaml
namespace: dev

# overlays/staging/kustomization.yaml
namespace: staging

# overlays/prod/kustomization.yaml
namespace: production
```

### Pattern 2: Environment Labels

```yaml
commonLabels:
  environment: production
  team: platform
```

### Pattern 3: Selective Resources

```yaml
# Don't deploy certain resources in dev
# overlays/dev/kustomization.yaml
resources:
  - ../../base
patches:
  - patch: |-
      $patch: delete
      apiVersion: v1
      kind: Service
      metadata:
        name: monitoring
```

## Best Practices

1. **Keep Base Minimal**: Only common resources
2. **Environment-Specific Namespaces**: Isolate environments
3. **Different Sync Policies**: Auto for dev/staging, manual for prod
4. **Version Pinning**: Use specific versions in production
5. **Resource Quotas**: Prevent resource exhaustion
6. **Testing**: Always test in dev/staging first

## Troubleshooting

### Kustomize Build Fails

```bash
# Test kustomize build
kubectl kustomize overlays/dev

# Check for syntax errors
kustomize build overlays/dev
```

### ArgoCD Out of Sync

```bash
# Check what changed
argocd app diff myapp-dev

# Force sync
argocd app sync myapp-dev --force
```

## Cleanup

```bash
# Delete all environments
argocd app delete myapp-dev --cascade
argocd app delete myapp-staging --cascade
argocd app delete myapp-prod --cascade

# Or delete ArgoCD apps
kubectl delete -f argocd-apps/
```

## Next Steps

- Try [Example 4](../04-app-of-apps/) to manage all environments together
- Add more environments (QA, pre-prod)
- Implement automated promotion pipelines
- Add environment-specific secrets management
