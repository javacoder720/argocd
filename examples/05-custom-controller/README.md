# Example 5: Custom Controller Pattern

This example demonstrates how to deploy a custom Kubernetes controller that watches and acts on Custom Resources.

## What You'll Learn

- Understand the controller/operator pattern
- Deploy a controller with proper RBAC
- Watch custom resources and reconcile state
- Implement the operator pattern with ArgoCD

## Controller Pattern

```
┌─────────────────────────────────────────┐
│         Kubernetes API Server           │
│  ┌────────────────────────────────┐    │
│  │  Custom Resources (Database)    │    │
│  └────────────────────────────────┘    │
└──────────────┬──────────────────────────┘
               │
               │ watches
               ▼
┌──────────────────────────────────────────┐
│       Custom Controller Pod              │
│  ┌────────────────────────────────────┐ │
│  │  1. Watch Database resources       │ │
│  │  2. Compare desired vs actual      │ │
│  │  3. Reconcile (create/update/del)  │ │
│  │  4. Update status                  │ │
│  └────────────────────────────────────┘ │
└──────────────┬───────────────────────────┘
               │
               │ creates/manages
               ▼
┌──────────────────────────────────────────┐
│    Actual Resources (Pods, Services)     │
└──────────────────────────────────────────┘
```

## Components

1. **CRD**: Defines the Database custom resource
2. **Controller**: Watches Database resources and creates Pods/Services
3. **RBAC**: ServiceAccount, Role, RoleBinding for permissions
4. **Deployment**: Runs the controller as a Pod

## Controller Logic (Conceptual)

```python
# Pseudocode for Database controller
while True:
    for database in watch_databases():
        desired_state = database.spec
        actual_state = get_actual_resources(database)

        if desired_state != actual_state:
            reconcile(database, desired_state, actual_state)
            update_status(database)
```

## Files

- `database-crd.yaml` - Custom Resource Definition
- `controller-rbac.yaml` - RBAC for controller
- `controller-deployment.yaml` - Controller deployment
- `example-database.yaml` - Example Database CR
- `argocd-app.yaml` - ArgoCD application

## Deployment

### Using ArgoCD

```bash
# Deploy the controller and CRD
kubectl apply -f argocd-app.yaml

# Verify controller is running
kubectl get pods -l app=database-controller

# Create a database
kubectl apply -f example-database.yaml

# Watch controller logs
kubectl logs -f -l app=database-controller
```

### Manual Deployment

```bash
# Deploy in order
kubectl apply -f database-crd.yaml
kubectl apply -f controller-rbac.yaml
kubectl apply -f controller-deployment.yaml

# Wait for controller to be ready
kubectl wait --for=condition=available deployment/database-controller

# Create a database resource
kubectl apply -f example-database.yaml
```

## Verify Controller

```bash
# Check controller pod
kubectl get pods -l app=database-controller

# View controller logs
kubectl logs -l app=database-controller

# Check RBAC
kubectl get serviceaccount database-controller
kubectl get role database-controller
kubectl get rolebinding database-controller

# Test creating a database
kubectl apply -f example-database.yaml
kubectl get databases
kubectl describe database my-postgres
```

## RBAC Permissions

The controller needs permissions to:
- **Watch**: Monitor Database custom resources
- **List/Get**: Read Database resources
- **Update**: Update Database status
- **Create/Update/Delete**: Manage Pods, Services, etc.

```yaml
rules:
  - apiGroups: ["data.example.com"]
    resources: ["databases"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["data.example.com"]
    resources: ["databases/status"]
    verbs: ["update", "patch"]
  - apiGroups: [""]
    resources: ["pods", "services"]
    verbs: ["get", "list", "create", "update", "delete"]
```

## Building a Real Controller

For a production controller, consider using:

### Option 1: Kubebuilder

```bash
# Install kubebuilder
curl -L -o kubebuilder https://go.kubebuilder.io/dl/latest/$(go env GOOS)/$(go env GOARCH)
chmod +x kubebuilder && mv kubebuilder /usr/local/bin/

# Create a new project
kubebuilder init --domain example.com
kubebuilder create api --group data --version v1 --kind Database
```

### Option 2: Operator SDK

```bash
# Install operator-sdk
brew install operator-sdk

# Create new operator
operator-sdk init --domain example.com
operator-sdk create api --group data --version v1 --kind Database
```

### Option 3: Python (Kopf)

```python
import kopf

@kopf.on.create('data.example.com', 'v1', 'databases')
def create_fn(spec, name, namespace, **kwargs):
    # Handle database creation
    print(f"Creating database: {name}")
    # Create pods, services, etc.

@kopf.on.update('data.example.com', 'v1', 'databases')
def update_fn(spec, name, namespace, **kwargs):
    # Handle database updates
    print(f"Updating database: {name}")

@kopf.on.delete('data.example.com', 'v1', 'databases')
def delete_fn(spec, name, namespace, **kwargs):
    # Handle database deletion
    print(f"Deleting database: {name}")
```

## Controller Best Practices

1. **Idempotent Operations**: Handle duplicate reconcile calls
2. **Status Updates**: Always update resource status
3. **Error Handling**: Retry transient errors, report permanent ones
4. **Finalizers**: Clean up external resources on deletion
5. **Leader Election**: Run multiple replicas for HA
6. **Metrics**: Expose Prometheus metrics
7. **Events**: Record events for debugging

## Example Controller Flow

```
1. User creates Database CR
   ↓
2. Controller watches and detects new Database
   ↓
3. Controller creates:
   - StatefulSet for database pods
   - Service for database access
   - PVC for storage
   ↓
4. Controller updates Database status:
   - phase: "Running"
   - endpoint: "my-db.default.svc:5432"
   ↓
5. User updates Database (change version)
   ↓
6. Controller detects change
   ↓
7. Controller performs rolling update
   ↓
8. Controller updates status
```

## Testing the Controller

```bash
# Create a database
kubectl apply -f example-database.yaml

# Watch the controller logs
kubectl logs -f -l app=database-controller

# Check database status
kubectl get database my-postgres -o yaml

# Update the database
kubectl patch database my-postgres -p '{"spec":{"version":"16.0"}}'

# Watch reconciliation
kubectl logs -f -l app=database-controller

# Delete the database
kubectl delete database my-postgres

# Verify cleanup
kubectl get all -l database=my-postgres
```

## Troubleshooting

### Controller Not Starting

```bash
# Check pod status
kubectl describe pod -l app=database-controller

# Check RBAC
kubectl auth can-i list databases --as=system:serviceaccount:default:database-controller

# Check logs
kubectl logs -l app=database-controller
```

### Controller Not Reconciling

```bash
# Verify CRD is registered
kubectl get crds | grep databases

# Check controller can list databases
kubectl get databases

# Restart controller
kubectl rollout restart deployment/database-controller
```

## Cleanup

```bash
# Delete via ArgoCD
argocd app delete database-controller --cascade

# Or manually
kubectl delete -f example-database.yaml
kubectl delete -f controller-deployment.yaml
kubectl delete -f controller-rbac.yaml
kubectl delete -f database-crd.yaml
```

## Next Steps

- Build a real controller using Kubebuilder or Operator SDK
- Add finalizers for cleanup logic
- Implement leader election for HA
- Add webhooks for validation/mutation
- Expose metrics for monitoring

## Resources

- [Kubebuilder Book](https://book.kubebuilder.io/)
- [Operator SDK](https://sdk.operatorframework.io/)
- [Kopf (Python)](https://kopf.readthedocs.io/)
- [Controller Runtime](https://github.com/kubernetes-sigs/controller-runtime)
