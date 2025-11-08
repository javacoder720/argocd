eksctl create cluster \
  --name my-eks \
  --region us-west-2 \
  --version 1.30 \
  --nodegroup-name ng-general \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 5 \
  --node-type t3.micro \
  --managed
