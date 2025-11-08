#!/bin/bash
set -e

echo "=========================================="
echo "ArgoCD Installation Script for EKS"
echo "=========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "Warning: helm is not installed. Helm installation method will not work."
fi

echo "✓ kubectl is installed"

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster"
    exit 1
fi

echo "✓ Connected to Kubernetes cluster"
kubectl cluster-info | grep "Kubernetes control plane"
echo ""

# Get installation method preference
echo "Select installation method:"
echo "1) kubectl (manifests)"
echo "2) Helm"
read -p "Enter choice [1-2]: " choice

case $choice in
    1)
        echo ""
        echo "Installing ArgoCD using kubectl..."

        # Create namespace
        kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

        # Install ArgoCD
        echo "Applying ArgoCD manifests..."
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

        ;;
    2)
        echo ""
        echo "Installing ArgoCD using Helm..."

        # Add Helm repository
        helm repo add argo https://argoproj.github.io/argo-helm
        helm repo update

        # Install ArgoCD
        helm install argocd argo/argo-cd \
            --namespace argocd \
            --create-namespace \
            --wait

        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=600s \
    deployment/argocd-server -n argocd

echo ""
echo "=========================================="
echo "ArgoCD Installation Complete!"
echo "=========================================="
echo ""

# Get initial admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)

echo "Initial Admin Credentials:"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
echo ""

echo "To access ArgoCD UI:"
echo "1. Port forward:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   Then visit: https://localhost:8080"
echo ""
echo "2. Or expose via LoadBalancer:"
echo "   kubectl patch svc argocd-server -n argocd -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'"
echo "   kubectl get svc argocd-server -n argocd"
echo ""

# Offer to start port-forward
read -p "Start port-forwarding now? [y/N]: " start_pf

if [[ $start_pf =~ ^[Yy]$ ]]; then
    echo ""
    echo "Starting port-forward on port 8080..."
    echo "Access ArgoCD at: https://localhost:8080"
    echo "Press Ctrl+C to stop"
    echo ""
    kubectl port-forward svc/argocd-server -n argocd 8080:443
fi
