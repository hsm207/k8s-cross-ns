#!/bin/bash

kubectl --namespace $RASAX_NS \
    create secret generic db-credentials \
    --from-literal=postgres=safe_credential