# Learning CRDs and ArgoCD on EKS

This guide covers Custom Resource Definitions (CRDs) and ArgoCD for GitOps on Amazon EKS.

## Table of Contents

1. [CRDs Fundamentals](./crds/README.md)
2. [ArgoCD Setup on EKS](./argocd/README.md)
3. [Practical Examples](./examples/README.md)

## Prerequisites

- AWS Account with EKS cluster running
- kubectl configured to access your EKS cluster
- Basic Kubernetes knowledge
- Helm 3 installed (for ArgoCD installation)

## Learning Path

### Phase 1: Understanding CRDs (30 mins)
Learn what CRDs are, why they're useful, and how to create them.

### Phase 2: ArgoCD Setup (45 mins)
Install and configure ArgoCD on your EKS cluster, set up authentication.

### Phase 3: GitOps with ArgoCD (1 hour)
Use ArgoCD to deploy applications and custom resources declaratively.

### Phase 4: Advanced Patterns (1 hour)
Combine CRDs with ArgoCD for powerful GitOps workflows.

## Quick Start

```bash
# Verify your EKS cluster access
kubectl cluster-info

# Check if you have admin permissions
kubectl auth can-i create customresourcedefinitions

# Start with CRDs basics
cd crds/

# Then move to ArgoCD
cd ../argocd/
```

## What You'll Learn

- **CRDs**: Create custom Kubernetes resources for domain-specific needs
- **Controllers**: Understand how controllers watch and act on custom resources
- **ArgoCD**: Implement GitOps patterns for continuous delivery
- **EKS Integration**: Deploy ArgoCD on EKS with best practices
- **Real Scenarios**: Build practical examples combining both technologies

## Resources

- [Kubernetes CRD Documentation](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
