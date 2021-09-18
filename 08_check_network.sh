#!/bin/bash

# setup
# get the name of the rasa x pod
rasax_name=`k get pods -n $RASAX_NS \
        -o custom-columns=name:.metadata.name \
        --no-headers | \
    grep $RASAX_NS-rasa-x`

# get the ip of the rasa x pod
rasax_ip=`kubectl get pods -n $RASAX_NS  $rasax_name  --no-headers     -o custom-columns=ipaddr:.status.podIP`

# create a busybox in the database namespace
cat <<EOF | kubectl -n $DB_NS apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  containers:
  - name: busybox
    image: busybox:1.28
    command:
      - sleep
      - "3600"
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
EOF

# create a busybox in the rasa-x namespace
cat <<EOF | kubectl -n $RASAX_NS apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  containers:
  - name: busybox
    image: busybox:1.28
    command:
      - sleep
      - "3600"
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
EOF

# python command to check db connectivity 
db_url=`echo postgresql+psycopg2://postgres:safe_credential@$postgres_svc_ip/rasa`
python_cmd=`echo "import sqlalchemy;sqlalchemy.create_engine('$db_url', echo=True, connect_args={'connect_timeout': 5}).connect()"`

# Test 1
# Test without any network policy in the database namesapce
printf "Test 1: No network policies defined\n"
printf "Run the following inside the rasa x container:\n$python_cmd\n"
kubectl -n $RASAX_NS exec -it $rasax_name -- python

printf "Pinging the rasa x pod from the database namespace ...\n"
kubectl -n $DB_NS exec -it busybox -- ping $rasax_ip

# Test 2
# Test with deny all ingress in the database namesapce
printf "Test 2: Creating a network policy to deny all ingress in the database namespace\n"

cat <<EOF | kubectl apply -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: deny-all-ingress
  namespace: $DB_NS
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
  - Ingress
EOF

printf "Run the following inside the rasa x container:\n$python_cmd\nThis will now timeout!\n"
kubectl -n $RASAX_NS exec -it $rasax_name -- python

printf "Pinging the rasa x pod from the database namespace ...\nThis will still work\n"
kubectl -n $DB_NS exec -it busybox -- ping $rasax_ip

# Test 3
# Test with deny all egress in the database namespace
printf "Test 3: Creating a network policy to deny all egress in the database namespace\n"
k delete -n $DB_NS  networkpolicy deny-all-ingress

cat <<EOF | kubectl apply -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: deny-all-egress
  namespace: $DB_NS
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
  - Egress
EOF

printf "Run the following inside the rasa x container:\n$python_cmd\nThis will still work\n"
kubectl -n $RASAX_NS exec -it $rasax_name -- python

printf "Pinging the rasa x pod from the database namespace ...\nThis will fail!\n"
kubectl -n $DB_NS exec -it busybox -- ping $rasax_ip

# Test 4
# Test with deny all ingress in the rasa x namespace
printf "Test 4: Creating a network policy to deny all ingress in the rasa x namespace\n"
k delete -n $DB_NS  networkpolicy deny-all-egress

cat <<EOF | kubectl apply -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: deny-all-ingress
  namespace: $RASAX_NS
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
  - Ingress
EOF

printf "Run the following inside the rasa x container:\n$python_cmd\nThis will still work\n"
kubectl -n $RASAX_NS exec -it $rasax_name -- python

printf "Pinging the rasa x pod from the database namespace ...\nThis will fail!\n"
kubectl -n $DB_NS exec -it busybox -- ping $rasax_ip

# Test 5
# Test with deny all egress in the rasa x namespace
printf "Test 5: Creating a network policy to deny all egress in the rasa x namespace\n"
k delete -n $RASAX_NS  networkpolicy deny-all-ingress


cat <<EOF | kubectl apply -f -
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: deny-all-egress
  namespace: $RASAX_NS
spec:
  podSelector:
    matchLabels: {}
  policyTypes:
  - Egress
EOF

printf "Run the following inside the rasa x container:\n$python_cmd\nThis will fail\n"
kubectl -n $RASAX_NS exec -it $rasax_name -- python

printf "Pinging the rasa x pod from the database namespace ...\nThis will work!\n"
kubectl -n $DB_NS exec -it busybox -- ping $rasax_ip

k delete -n $RASAX_NS  networkpolicy deny-all-egress 