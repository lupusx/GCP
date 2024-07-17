kubectl get svc frontend -o=jsonpath="{.status.loadBalancer.ingress[0].ip

kubectl explain deployment.spec.replicas

kubectl get pods -o jsonpath --template='{range .items[*]}{.metadata.name}{"\t"}{"\t"}{.spec.containers[0].image}{"\n"}{end}'

kubectl rollout resume deployment/hello

kubectl rollout status deployment/hello


kubectl rollout undo deployment/hello

curl -ks https://`kubectl get svc frontend -o=jsonpath="{.status.loadBalancer.ingress[0].ip}"`/version

kubectl apply -f services/hello-blue.yaml