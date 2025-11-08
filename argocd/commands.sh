  eksctl create nodegroup \
    --cluster=argocd-cluster \
    --region=us-east-1 \
    --name=small-workers \
    --node-type=t3.small \
    --nodes=2 \
    --nodes-min=2 \
    --nodes-max=2 \
    --managed
  yes | eksctl delete nodegroup \
    --cluster=argocd-cluster \
    --region=us-east-1 \
    --name=standard-workers \
    --drain
  eksctl get nodegroup --cluster=argocd-cluster --region=us-east-1

  # destroy and recreate
  helm list -n argocd
  helm uninstall argocd -n argocd
  kubectl delete namespace argocd
  helm install argocd argo/argo-cd \
    --namespace argocd \
    --create-namespace \
    --set server.service.type=LoadBalancer


# login to argocd
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure
  argocd account update-password

# argocd
argocd app create guestbook \
  --repo https://github.com/argoproj/argocd-example-apps.git \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
argocd app sync guestbook
argocd app get guestbook


helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=argocd-cluster


kubectl tree -n kube-system pod/aws-load-balancer-controller-67f48ccdbb-brsvb
