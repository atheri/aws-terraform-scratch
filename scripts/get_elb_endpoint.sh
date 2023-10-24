JSON=""
while [ -z "$JSON" ]; do
  JSON=$(kubectl get service echo-server -o=jsonpath='{.status.loadBalancer.ingress[0]}')
done
echo "$JSON"