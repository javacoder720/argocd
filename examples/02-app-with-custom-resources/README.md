# Example 2: Application with Custom Resources

This example shows how to deploy a complete application that uses custom resources alongside standard Kubernetes resources.

## What You'll Learn

- Combine CRDs with standard Kubernetes resources
- Manage dependencies between resources
- Use custom resources in application deployments
- Track application status through custom resources

## Architecture

```
Application Stack:
├── CRD (Database)
├── Custom Resource (PostgreSQL instance)
├── Deployment (Application pods)
├── Service (Expose application)
├── ConfigMap (Application config)
└── Secret (Database credentials)
```

## Scenario

Deploy a web application with:
- Custom Database resource (managed by hypothetical operator)
- Application deployment that connects to the database
- ConfigMap for app configuration
- Service to expose the app

## Files

- `database-crd.yaml` - Database CRD definition
- `database.yaml` - PostgreSQL database instance
- `app-deployment.yaml` - Application deployment
- `app-service.yaml` - Service to expose app
- `app-configmap.yaml` - Application configuration
- `app-secret.yaml` - Database credentials (Secret)
- `argocd-app.yaml` - ArgoCD application definition
- `base/` - Kustomize base configuration
- `overlays/dev/` - Development environment overlay
- `overlays/prod/` - Production environment overlay

## Prerequisites

```bash
# Verify ArgoCD is running
kubectl get pods -n argocd

# Check cluster access
kubectl cluster-info
```

## Deployment

### Using ArgoCD

```bash
# Deploy the application
kubectl apply -f argocd-app.yaml

# Check status
argocd app get app-with-crds

# Wait for sync to complete
argocd app wait app-with-crds --timeout 300
```

### Manual Deployment

```bash
# Deploy in order
kubectl apply -f database-crd.yaml
kubectl apply -f database.yaml
kubectl apply -f app-configmap.yaml
kubectl apply -f app-secret.yaml
kubectl apply -f app-deployment.yaml
kubectl apply -f app-service.yaml

# Verify
kubectl get databases
kubectl get pods
kubectl get svc
```

### Using Kustomize

```bash
# Deploy to dev environment
kubectl apply -k overlays/dev

# Deploy to prod environment
kubectl apply -k overlays/prod

# Preview without applying
kubectl kustomize overlays/dev
kubectl kustomize overlays/prod
```

## Verify Deployment

```bash
# Check database custom resource
kubectl get database app-postgres
kubectl describe database app-postgres

# Check application pods
kubectl get pods -l app=web-app

# Check service
kubectl get svc web-app

# Get application logs
kubectl logs -l app=web-app
```

## Resource Dependencies

The deployment uses sync waves to ensure proper ordering:

1. **Wave 0**: Database CRD
2. **Wave 1**: Database custom resource
3. **Wave 2**: ConfigMap (with database connection info)
4. **Wave 3**: Application deployment
5. **Wave 4**: Service

## Testing

```bash
# Port forward to application
kubectl port-forward svc/web-app 8080:80

# Test the application
curl http://localhost:8080

# Check database connection
kubectl logs -l app=web-app | grep -i database
```

## Customization

### Change Database Version

Edit `database.yaml`:

```yaml
spec:
  engine: postgres
  version: "16.0"  # Change version
  storageSize: "50Gi"  # Increase storage
```

Commit and push - ArgoCD will sync automatically.

### Scale Application

```bash
# Edit deployment
kubectl edit deployment web-app

# Or via GitOps - edit app-deployment.yaml:
spec:
  replicas: 5  # Scale to 5 replicas
```

## Cleanup

```bash
# Delete via ArgoCD
argocd app delete app-with-crds --cascade

# Or manually
kubectl delete -f .
```

## Kustomize Environments

This example includes two Kustomize overlays:

### Development (overlays/dev/)
- 1 replica
- 10Gi storage
- Debug logging
- Lower resource limits
- Deployed to `dev` namespace

### Production (overlays/prod/)
- 5 replicas
- 100Gi storage
- PostgreSQL 16.0
- Warn-level logging
- Higher resource limits
- Deployed to `prod` namespace

## Next Steps

- Try [Example 3](../03-multi-environment/) for multi-environment setup
- Modify the custom resource schema
- Add health checks to the application
- Create additional overlays for staging
