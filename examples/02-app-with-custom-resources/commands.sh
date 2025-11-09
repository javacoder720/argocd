kustomize edit fix

# argo set up
helm install argocd argo/argo-cd \
    --namespace argocd \
    --create-namespace \
    --set server.service.type=LoadBalancer
kubectl port-forward service/argocd-server -n argocd 8080:443

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure



