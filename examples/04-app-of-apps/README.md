# Example 4: App of Apps Pattern

The App of Apps pattern allows you to manage multiple ArgoCD applications declaratively. A parent application deploys child applications.

## What You'll Learn

- Implement the App of Apps pattern
- Manage multiple applications with one manifest
- Organize applications by team or environment
- Control deployment dependencies

## Architecture

```
┌─────────────────────────────────────────┐
│      Root Application (App of Apps)     │
└────────────┬────────────────────────────┘
             │
             ├─── Infrastructure Apps
             │    ├── Namespaces
             │    ├── RBAC
             │    └── CRDs
             │
             ├─── Platform Apps
             │    ├── Ingress Controller
             │    ├── Cert Manager
             │    └── Monitoring
             │
             └─── Application Apps
                  ├── Frontend
                  ├── Backend API
                  └── Database
```

## Directory Structure

```
04-app-of-apps/
├── root-app.yaml          # Parent ArgoCD application
├── apps/
│   ├── infrastructure/    # Core infrastructure
│   │   ├── namespaces.yaml
│   │   ├── crds.yaml
│   │   └── rbac.yaml
│   ├── platform/         # Platform services
│   │   ├── ingress.yaml
│   │   └── monitoring.yaml
│   └── applications/     # Business applications
│       ├── frontend.yaml
│       ├── backend.yaml
│       └── database.yaml
```

## Benefits

1. **Single Source of Truth**: One application manages all others
2. **Declarative**: Applications defined in Git
3. **Dependency Management**: Control deployment order with sync waves
4. **Easy Rollback**: Git revert affects all apps
5. **Visibility**: See all applications in one place

## Implementation

### Step 1: Create Child Applications

Each child is a standard ArgoCD Application:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: frontend
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "2"  # Deploy after infrastructure
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/myrepo
    path: apps/frontend
  destination:
    server: https://kubernetes.default.svc
    namespace: frontend
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Step 2: Create Root Application

The root app points to the directory containing child apps:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/myrepo
    path: apps
    directory:
      recurse: true  # Include subdirectories
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
```

### Step 3: Deploy Root Application

```bash
# Apply the root application
kubectl apply -f root-app.yaml

# Watch as it creates child applications
argocd app list

# View in UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Sync Waves for Dependencies

Use annotations to control deployment order:

```yaml
# Wave 0: Infrastructure (CRDs, Namespaces)
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"

# Wave 1: Platform Services (Ingress, Monitoring)
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"

# Wave 2: Applications (Frontend, Backend)
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "2"
```

## Deployment

### Deploy Everything

```bash
# Deploy the root application
kubectl apply -f root-app.yaml

# Sync all applications
argocd app sync root-app

# Check status
argocd app get root-app
argocd app list
```

### View Application Tree

```bash
# See parent-child relationships
argocd app get root-app --show-tree

# In UI, navigate to root-app to see all children
```

## Managing Changes

### Add a New Application

1. Create application manifest in `apps/` directory
2. Commit and push to Git
3. Root app automatically syncs and creates new child

```bash
# Add new app
cat > apps/applications/cache.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: redis-cache
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/myrepo
    path: apps/redis
  destination:
    server: https://kubernetes.default.svc
    namespace: cache
EOF

git add apps/applications/cache.yaml
git commit -m "Add Redis cache application"
git push
```

### Remove an Application

1. Delete application manifest from Git
2. Commit and push
3. Root app prunes deleted child (if prune enabled)

## Organization Patterns

### Pattern 1: By Environment

```
apps/
├── production/
│   ├── frontend.yaml
│   └── backend.yaml
├── staging/
│   ├── frontend.yaml
│   └── backend.yaml
└── development/
    ├── frontend.yaml
    └── backend.yaml
```

### Pattern 2: By Team

```
apps/
├── team-alpha/
│   ├── service-a.yaml
│   └── service-b.yaml
├── team-beta/
│   ├── service-c.yaml
│   └── service-d.yaml
└── platform/
    ├── ingress.yaml
    └── monitoring.yaml
```

### Pattern 3: By Layer

```
apps/
├── 00-infrastructure/
│   ├── namespaces.yaml
│   └── crds.yaml
├── 01-platform/
│   ├── ingress.yaml
│   └── cert-manager.yaml
└── 02-applications/
    ├── frontend.yaml
    └── backend.yaml
```

## Advanced Features

### Selective Sync

Sync only specific applications:

```bash
# Sync only infrastructure apps
argocd app sync -l wave=0

# Sync specific child app
argocd app sync frontend
```

### Health Checks

Root app shows health of all children:

```bash
# Check health
argocd app get root-app

# See unhealthy apps
argocd app list --selector health-status=Degraded
```

### Cascading Delete

Delete root app and all children:

```bash
# Delete everything
argocd app delete root-app --cascade

# Or keep children
argocd app delete root-app --cascade=false
```

## Monitoring

### Track Sync Status

```bash
# List all applications with status
argocd app list

# Watch for changes
watch argocd app list

# Get detailed status
argocd app get root-app --show-operation
```

### Prometheus Metrics

Root app exposes metrics for all children:
- Sync status
- Health status
- Last sync time
- Resource count

## Troubleshooting

### Issue: Child app not created

**Check**:
```bash
# Verify root app synced
argocd app get root-app

# Check for errors in root app
argocd app get root-app --show-operation

# Verify directory recursion
argocd app get root-app -o yaml | grep recurse
```

### Issue: Sync order wrong

**Solution**: Use sync waves in child app annotations

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"  # Lower = earlier
```

### Issue: Changes not detected

**Check Git**:
```bash
# Force refresh
argocd app get root-app --refresh

# Check repo connection
argocd repo list
```

## Best Practices

1. **Sync Waves**: Use waves for clear dependencies
2. **Naming**: Use consistent naming (team-service, env-app)
3. **Projects**: Use AppProjects for RBAC
4. **Auto-Sync**: Enable for non-production environments
5. **Prune**: Be careful with prune in production
6. **Documentation**: Document dependencies between apps

## Cleanup

```bash
# Delete all applications
argocd app delete root-app --cascade

# Or via kubectl
kubectl delete -f root-app.yaml
```

## Next Steps

- Set up App of Apps for your organization
- Implement multi-environment setup
- Add sync windows for production apps
- Explore [Example 5](../05-custom-controller/) for operator patterns
