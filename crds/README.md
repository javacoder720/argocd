# Custom Resource Definitions (CRDs)

## What are CRDs?

Custom Resource Definitions extend Kubernetes API to manage custom resources. They allow you to create your own API objects that behave like native Kubernetes resources.

## Why Use CRDs?

- **Domain-Specific Resources**: Model your application's concepts (e.g., Database, Cache, Application)
- **Declarative API**: Use kubectl and YAML manifests
- **Built-in Features**: Get validation, versioning, and RBAC for free
- **Controller Pattern**: Watch and react to custom resource changes

## CRD Architecture

```
┌─────────────────────────────────────────┐
│         Kubernetes API Server           │
│  ┌────────────┐      ┌──────────────┐  │
│  │   Native   │      │    Custom    │  │
│  │  Resources │      │   Resources  │  │
│  │ (Pod, Svc) │      │   (via CRD)  │  │
│  └────────────┘      └──────────────┘  │
└─────────────────────────────────────────┘
                 ▲
                 │ watches
                 │
       ┌─────────┴──────────┐
       │   Custom Controller │
       │  (reconciliation)   │
       └────────────────────┘
```

## Basic CRD Example

See [application-crd.yaml](./application-crd.yaml) for a complete example.

## Creating Your First CRD

### Step 1: Define the CRD

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: applications.example.com
spec:
  group: example.com
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                image:
                  type: string
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 10
  scope: Namespaced
  names:
    plural: applications
    singular: application
    kind: Application
    shortNames:
    - app
```

### Step 2: Apply the CRD

```bash
kubectl apply -f application-crd.yaml
kubectl get crds
```

### Step 3: Create a Custom Resource Instance

```yaml
apiVersion: example.com/v1
kind: Application
metadata:
  name: my-app
spec:
  image: nginx:1.21
  replicas: 3
```

### Step 4: Manage Your Custom Resource

```bash
# Create
kubectl apply -f my-app.yaml

# List
kubectl get applications
kubectl get app  # using short name

# Describe
kubectl describe application my-app

# Delete
kubectl delete application my-app
```

## CRD Schema Validation

CRDs support OpenAPI v3 schema for validation:

```yaml
schema:
  openAPIV3Schema:
    type: object
    required: ["spec"]
    properties:
      spec:
        type: object
        required: ["image"]
        properties:
          image:
            type: string
            pattern: '^[a-zA-Z0-9._/-]+:[a-zA-Z0-9._-]+$'
          replicas:
            type: integer
            minimum: 1
            maximum: 100
            default: 1
          environment:
            type: string
            enum: ["dev", "staging", "prod"]
```

## CRD Status Subresource

Enable status tracking for your custom resources:

```yaml
spec:
  versions:
    - name: v1
      subresources:
        status: {}
```

This allows controllers to update status separately from spec:

```yaml
apiVersion: example.com/v1
kind: Application
metadata:
  name: my-app
spec:
  image: nginx:1.21
  replicas: 3
status:
  availableReplicas: 3
  conditions:
    - type: Ready
      status: "True"
      lastTransitionTime: "2025-11-06T10:00:00Z"
```

## Additional Printer Columns

Show custom columns in `kubectl get` output:

```yaml
spec:
  versions:
    - name: v1
      additionalPrinterColumns:
      - name: Image
        type: string
        jsonPath: .spec.image
      - name: Replicas
        type: integer
        jsonPath: .spec.replicas
      - name: Status
        type: string
        jsonPath: .status.conditions[?(@.type=="Ready")].status
      - name: Age
        type: date
        jsonPath: .metadata.creationTimestamp
```

## Hands-On Exercises

### Exercise 1: Database CRD
Create a CRD for managing databases with fields like engine, version, size.

### Exercise 2: Validation
Add schema validation to ensure version follows semver format.

### Exercise 3: Status Tracking
Add status subresource to track connection state and health.

## Common Patterns

### 1. Configuration Objects
```yaml
kind: DatabaseConfig
spec:
  maxConnections: 100
  timeout: 30s
```

### 2. Application Definitions
```yaml
kind: Application
spec:
  components:
    - name: frontend
      image: frontend:v1
    - name: backend
      image: backend:v1
```

### 3. Operators
CRDs are the foundation for Kubernetes Operators:
- Define custom resources
- Write controllers to watch them
- Implement reconciliation logic

## Best Practices

1. **Naming**: Use reverse DNS format (e.g., `myapp.company.com`)
2. **Versioning**: Plan for API evolution with v1alpha1, v1beta1, v1
3. **Validation**: Use schema validation to catch errors early
4. **Documentation**: Add descriptions to all fields
5. **Status**: Separate spec (desired state) from status (observed state)
6. **Short Names**: Provide convenient aliases for kubectl

## Next Steps

- Review the example CRDs in this directory
- Try creating and managing custom resources
- Move on to [ArgoCD](../argocd/README.md) to deploy CRDs with GitOps
- Explore [examples](../examples/README.md) for real-world scenarios
