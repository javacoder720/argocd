# Example 1: Basic CRD Deployment with ArgoCD

This example demonstrates how to deploy a Custom Resource Definition and its instances using ArgoCD.

## What You'll Learn

- Deploy CRDs using ArgoCD
- Use sync waves to control deployment order
- Create and manage custom resources through GitOps

## Architecture

```
ArgoCD Application
    │
    ├── Sync Wave 0: CRD Installation
    │   └── databases.data.example.com
    │
    └── Sync Wave 1: Custom Resources
        ├── dev-postgres (Database)
        └── prod-mysql (Database)
```

## Prerequisites

- ArgoCD installed on EKS
- kubectl access to cluster
- Git repository (or use this locally)

## Files

- `database-crd.yaml` - Custom Resource Definition
- `databases.yaml` - Custom Resource instances
- `argocd-app.yaml` - ArgoCD Application definition

## Steps

### 1. Review the CRD

The CRD defines a `Database` resource with the following fields:
- `engine`: postgres, mysql, mongodb, redis
- `version`: Database version
- `storageSize`: Storage allocation
- `backup`: Backup configuration

### 2. Deploy Using ArgoCD

```bash
# Option A: Deploy the ArgoCD application
kubectl apply -f argocd-app.yaml

# Option B: Create via CLI
argocd app create basic-crd-example \
  --repo https://github.com/YOUR-ORG/YOUR-REPO \
  --path examples/01-basic-crd-deployment \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated
```

### 3. Verify Deployment

```bash
# Check ArgoCD application status
argocd app get basic-crd-example
argocd app resources basic-crd-example
argocd app manifests basic-crd-example

# Verify CRD installation
kubectl get crds | grep databases.data.example.com

# List custom resources
kubectl get databases

# Describe a database
kubectl describe database dev-postgres
```

### 4. Expected Output

```
NAME           ENGINE     VERSION   STORAGE   PHASE     ENDPOINT   AGE
dev-postgres   postgres   15.3      20Gi      Running   ...        2m
prod-mysql     mysql      8.0       100Gi     Running   ...        2m
```

## Understanding Sync Waves

The manifests use sync wave annotations:

```yaml
# CRD - installed first
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"

# Custom Resources - installed after CRD
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
```

This ensures the CRD exists before creating instances.

## Modifying Resources

### Add a New Database

1. Edit `databases.yaml`:

```yaml
---
apiVersion: data.example.com/v1
kind: Database
metadata:
  name: staging-redis
  annotations:
    argocd.argoproj.io/sync-wave: "1"
spec:
  engine: redis
  version: "7.0"
  storageSize: 10Gi
```

2. Commit and push to Git
3. ArgoCD will automatically sync (if auto-sync enabled)

```bash
# Or manually sync
argocd app sync basic-crd-example
```

### Update Database Configuration

1. Edit the database spec in Git
2. Commit changes
3. Watch ArgoCD apply updates

```bash
argocd app sync basic-crd-example --watch
```

## Cleanup

### Option 1: Delete via ArgoCD

```bash
# Delete the application (keeps resources by default)
argocd app delete basic-crd-example

# Delete and cascade (removes all resources)
argocd app delete basic-crd-example --cascade
```

### Option 2: Delete Manually

```bash
# Delete custom resources
kubectl delete database dev-postgres prod-mysql

# Delete CRD (this will delete all instances!)
kubectl delete crd databases.data.example.com

# Delete ArgoCD application
kubectl delete -f argocd-app.yaml
```

## Troubleshooting

### Issue: CRD not found

**Symptom**: Custom resources fail to create

**Solution**:
```bash
# Check CRD exists
kubectl get crds | grep databases

# Check sync wave order
kubectl get -f database-crd.yaml -o yaml | grep sync-wave

# Force sync
argocd app sync basic-crd-example --force
```

### Issue: Validation errors

**Symptom**: Custom resource rejected by API

**Solution**:
```bash
# Validate locally first
kubectl apply --dry-run=client -f databases.yaml

# Check CRD schema
kubectl get crd databases.data.example.com -o yaml
```

## Next Steps

- Try [Example 2](../02-app-with-custom-resources/) to see CRDs in a full application
- Modify the CRD schema and add new fields
- Add status tracking to the CRD
