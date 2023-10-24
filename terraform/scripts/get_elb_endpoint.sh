JSON=""
while [ -z "$JSON" ]; do
  JSON=$(kubectl get service echo-server -o=jsonpath='{.status.loadBalancer.ingress[0]}')
done

ENDPOINT=$(kubectl get service echo-server -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')
until host "$ENDPOINT" > /dev/null ;do sleep 1; done

echo "$JSON"