#!/bin/bash

postgres_svc_ip=`kubectl get service -n $DB_NS \
    --no-headers  $DB_NS-postgresql \
    -o custom-columns=ipaddr:.spec.clusterIP`

kubectl create -f https://k8s.io/examples/admin/dns/busybox.yaml

sleep 5

postgres_svc_fqn=`kubectl exec -it busybox -- nslookup $postgres_svc_ip | \
    grep Address | \
    tail -1 | \
    cut -f 4 -d \  | \
    tr -d '\n'`

echo "The FQN of the postgresql service is: $postgres_svc_fqn"

cat <<EOF > values.nodb.yml
postgresql:
    install: false 
    existingHost: $postgres_svc_fqn
    existingSecretKey: postgres

global:
    postgresql:
        existingSecret: db-credentials
EOF

kubectl delete pod busybox
