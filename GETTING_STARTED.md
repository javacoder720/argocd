# Getting Started with CRDs and ArgoCD on EKS

Quick start guide to begin learning CRDs and ArgoCD.

## Prerequisites Checklist

- [ ] AWS Account with EKS cluster
- [ ] `kubectl` installed and configured
- [ ] `helm` installed (v3+)
- [ ] `argocd` CLI installed (optional but recommended)
- [ ] Git repository for your manifests

## Quick Start (30 minutes)

### Step 1: Verify EKS Access (2 min)

```bash
# Check cluster connectivity
kubectl cluster-info

# Verify you can create resources
kubectl auth can-i create customresourcedefinitions
# Should return: yes
```

### Step 2: Install ArgoCD (5 min)

```bash
# Run the installation script
cd k8s/crds-argocd/argocd
./install.sh

# Or manually:
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ready
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
```

### Step 3: Access ArgoCD (3 min)

```bash
# Get admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
echo "Password: $ARGOCD_PASSWORD"

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser to https://localhost:8080
# Username: admin
# Password: <from above>
```

### Step 4: Create Your First CRD (5 min)

```bash
# Apply the Application CRD
kubectl apply -f k8s/crds-argocd/crds/application-crd.yaml

# Verify
kubectl get crds | grep applications.example.com

# Create a custom resource
kubectl apply -f k8s/crds-argocd/crds/example-application.yaml

# List applications
kubectl get applications
```

### Step 5: Deploy with ArgoCD (10 min)

```bash
# Create your first ArgoCD application
kubectl apply -f k8s/crds-argocd/examples/01-basic-crd-deployment/argocd-app.yaml

# Check status
argocd app list
argocd app get basic-crd-example

# View in UI at https://localhost:8080
```

### Step 6: Make a Change (5 min)

```bash
# Edit a custom resource
kubectl edit application nginx-app

# Watch ArgoCD detect and sync the change
argocd app sync basic-crd-example --watch
```

## Learning Path

### Beginner (1-2 hours)

1. **Understand CRDs** - Read [crds/README.md](./crds/README.md)
2. **Install ArgoCD** - Follow [argocd/README.md](./argocd/README.md)
3. **Basic Example** - Complete [Example 1](./examples/01-basic-crd-deployment/)

### Intermediate (2-3 hours)

4. **Application Patterns** - Review [example applications](./argocd/example-app.yaml)
5. **Multi-Environment** - Set up dev/staging/prod
6. **App of Apps** - Implement [Example 4](./examples/04-app-of-apps/)

### Advanced (3-4 hours)

7. **Custom Controllers** - Build a CRD controller
8. **RBAC & Projects** - Set up multi-tenancy
9. **Production Setup** - Ingress, TLS, monitoring

## Common Tasks

### Create a CRD

```bash
# Use the template
cp crds/application-crd.yaml crds/my-resource-crd.yaml

# Edit the CRD
# - Change group, kind, names
# - Define schema properties
# - Add validation rules

# Apply
kubectl apply -f crds/my-resource-crd.yaml
```

### Deploy an Application

```bash
# Option 1: Using kubectl
kubectl apply -f argocd/example-app.yaml

# Option 2: Using ArgoCD CLI
argocd app create my-app \
  --repo https://github.com/myorg/myrepo \
  --path apps/my-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Sync
argocd app sync my-app
```

### Debug Issues

```bash
# Check ArgoCD application status
argocd app get my-app

# View sync errors
argocd app get my-app --show-operation

# Check resource status
kubectl get all -n my-namespace

# View ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller
kubectl logs -n argocd deployment/argocd-server

# Validate manifests locally
kubectl apply --dry-run=client -f my-manifest.yaml
```

## Next Steps

Choose your path:

### Path 1: CRD Focus
1. Read [CRD fundamentals](./crds/README.md)
2. Create custom CRDs for your domain
3. Add validation and status tracking
4. Build a simple controller

### Path 2: ArgoCD Focus
1. Read [ArgoCD guide](./argocd/README.md)
2. Set up GitOps workflow
3. Implement App of Apps pattern
4. Configure multi-environment deployment

### Path 3: Combined Approach
1. Complete [Example 1](./examples/01-basic-crd-deployment/) - Basic CRD deployment
2. Complete [Example 4](./examples/04-app-of-apps/) - App of Apps pattern
3. Set up your own Git repository
4. Build a real application with custom resources

## Resources

### Documentation
- [Kubernetes CRD Docs](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

### Examples in This Repository
- [CRD Examples](./crds/)
- [ArgoCD Applications](./argocd/)
- [Complete Examples](./examples/)

### Commands Reference

```bash
# CRD commands
kubectl get crds
kubectl describe crd <name>
kubectl get <custom-resource-plural>

# ArgoCD commands
argocd app list
argocd app get <app-name>
argocd app sync <app-name>
argocd app delete <app-name>

# Debugging
kubectl describe application <name>
kubectl logs -n argocd deployment/argocd-server
argocd app diff <app-name>
```

## Troubleshooting

### ArgoCD not syncing
- Check repository credentials: `argocd repo list`
- Verify path in Application spec
- Check ArgoCD logs: `kubectl logs -n argocd deployment/argocd-application-controller`

### CRD not found
- Verify CRD is installed: `kubectl get crds`
- Check sync wave ordering
- Ensure CRD is applied before custom resources

### Permission denied
- Check RBAC: `kubectl auth can-i create <resource>`
- Verify service account permissions
- Review AppProject restrictions

## Getting Help

1. Check the README files in each directory
2. Review example manifests
3. Read ArgoCD documentation
4. Check Kubernetes CRD documentation

Happy learning!
